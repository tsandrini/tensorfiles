"""Push, pull and status: the generation protocol on top of the store.

Every unit has one canonical copy on the relay, stamped with a generation.
Each host remembers the generation its local copy corresponds to and the
fingerprint it is expected to have (the baseline). From those two facts:

- push refuses when the relay moved on since the baseline (pull first),
- pull sets a changed local copy aside under `conflicts/` before overwriting,
- status tells `in sync` / `push pending` / `pull pending` / `conflict` apart
  without touching anything.

Transfers never rely on remote timestamps: the file sets recorded on both
sides (size, nanosecond mtime, mode, link target) decide what moves, and the
puller restores times, modes, links and directories itself.
"""

from __future__ import annotations

import contextlib
import os
import sys
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path

from handoff.config import Config
from handoff.errors import RelayError, UsageError
from handoff.fileset import EMPTY, KIND_DIR, KIND_FILE, KIND_LINK, FileSet
from handoff.state import StateStore, UnitState
from handoff.store import Meta, Store
from handoff.units.git import GitRepo, discover, unit_for

MIB = 1024 * 1024


def say(text: str) -> None:
    """Progress line for the user, on stderr so `--json` output stays clean.

    Args:
        text: The line.
    """
    print(f"handoff: {text}", file=sys.stderr, flush=True)


def now() -> str:
    """Current UTC time as an ISO timestamp with second precision."""
    return datetime.now(UTC).isoformat(timespec="seconds")


def stamp() -> str:
    """Filesystem-safe timestamp for history and conflict directories."""
    return datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")


@dataclass(frozen=True)
class Outcome:
    """What happened to one unit.

    Attributes:
        unit_id: Unit id.
        action: One of `pushed`, `pulled`, `adopted`, `unchanged`, `up to date`,
            `skipped`, `conflict`, `failed`, `would push`, `would pull`.
        detail: Human-readable explanation.
    """

    unit_id: str
    action: str
    detail: str = ""

    @property
    def failed(self) -> bool:
        """Whether the outcome should fail the command."""
        return self.action in {"conflict", "skipped", "failed"}


@dataclass(frozen=True)
class UnitStatus:
    """Status row of one unit.

    Attributes:
        unit_id: Unit id.
        local: `clean`, `changed`, `missing`, or a blocker reason.
        relay_host: Host of the canonical copy, `None` if never pushed.
        relay_time: Push time of the canonical copy, `None` if never pushed.
        state: `in sync`, `push pending`, `pull pending`, `conflict`,
            `never pushed`, `not local`, `diverged`, `unadopted`, `blocked`.
    """

    unit_id: str
    local: str
    relay_host: str | None
    relay_time: str | None
    state: str


@dataclass
class _Push:
    unit: GitRepo
    fileset: FileSet
    fingerprint: str
    meta: Meta | None
    uploads: list[str] | None = None
    removals: list[str] | None = None


@dataclass
class _Pull:
    unit: GitRepo
    meta: Meta
    fileset: FileSet | None  # local, None when the unit does not exist yet
    previous: FileSet
    take_relay: bool
    set_aside: str | None
    relay: FileSet | None = None
    downloads: list[str] | None = None
    deletions: list[str] | None = None


def select(requested: list[str], candidates: list[str]) -> list[str]:
    """Resolve unit ids given on the command line.

    Args:
        requested: Exact ids, or prefixes ending with `/` (a whole bundle);
            everything when empty.
        candidates: Known ids.

    Returns:
        The selected ids in candidate order.

    Raises:
        UsageError: A name matches nothing.
    """
    if not requested:
        return list(candidates)
    chosen: list[str] = []
    for name in requested:
        hits = (
            [c for c in candidates if c.startswith(name)]
            if name.endswith("/")
            else [c for c in candidates if c == name]
        )
        if not hits:
            raise UsageError(f"{name!r} matches no unit")
        chosen.extend(h for h in hits if h not in chosen)
    return chosen


def plan_upload(current: FileSet, base: FileSet) -> tuple[list[str], list[str]]:
    """Regular files to upload and to remove so that `base` becomes `current`.

    Args:
        current: Local file set.
        base: What the relay holds.

    Returns:
        Paths to upload and paths to remove.
    """
    base_index = base.index()
    uploads = [
        e.path for e in current.of_kind(KIND_FILE) if not e.same_content(base_index.get(e.path))
    ]
    current_paths = set(current.paths)
    removals = [e.path for e in base.of_kind(KIND_FILE) if e.path not in current_paths]
    return uploads, removals


def materialize(root: Path, target: FileSet, downloaded: set[str]) -> None:
    """Make directories, links, times and modes below `root` match `target`.

    Args:
        root: Local unit directory.
        target: The relay's file set.
        downloaded: Paths rclone just wrote, whose times and modes need fixing.
    """
    for e in target.entries:
        p = root / e.path
        if e.kind == KIND_DIR:
            if not p.is_dir():
                p.mkdir(parents=True, exist_ok=True)
        elif e.kind == KIND_LINK:
            if p.is_symlink() and str(p.readlink()) == e.target:
                continue
            if p.is_symlink() or p.is_file():
                p.unlink()
            p.parent.mkdir(parents=True, exist_ok=True)
            p.symlink_to(e.target)
        elif p.is_file() and not p.is_symlink():
            st = p.stat()
            if (st.st_mode & 0o7777) != e.mode:
                p.chmod(e.mode)
            if e.path in downloaded or st.st_mtime_ns != e.mtime:
                os.utime(p, ns=(e.mtime, e.mtime))


def prune(root: Path, paths: list[str]) -> None:
    """Delete files and links, then drop the listed directories once empty.

    Args:
        root: Local unit directory.
        paths: Relative paths that no longer belong to the unit.
    """
    dirs = []
    for rel in paths:
        p = root / rel
        if p.is_symlink() or p.is_file():
            p.unlink()
        elif p.is_dir():
            dirs.append(p)
    for p in sorted(dirs, key=lambda d: len(d.parts), reverse=True):
        with contextlib.suppress(OSError):
            p.rmdir()


class Engine:
    """Push/pull/status against one relay."""

    def __init__(self, config: Config, store: Store, state: StateStore) -> None:
        """Bind config, store and state.

        Args:
            config: Parsed config.
            store: Relay to talk to.
            state: Per-host state for that relay.
        """
        self.config = config
        self.store = store
        self.state = state
        self._meta: dict[str, Meta] | None = None

    @property
    def meta(self) -> dict[str, Meta]:
        """Generation stamps on the relay (fetched once)."""
        if self._meta is None:
            self._meta = self.store.fetch_meta()
        return self._meta

    def _adopt(self, unit_id: str, meta: Meta, fileset: FileSet) -> None:
        self.state.save(unit_id, UnitState(meta.generation, meta.fingerprint, now()), fileset)

    # --- push ---

    def push(
        self, units: list[GitRepo], *, force: bool = False, dry_run: bool = False
    ) -> list[Outcome]:
        """Push every given unit, transferring everything in one batch.

        Args:
            units: Local units.
            force: Overwrite a relay copy this host has no baseline for.
            dry_run: Only report.

        Returns:
            One outcome per unit, in order.
        """
        outcomes: dict[str, Outcome] = {}
        plans: list[_Push] = []
        for unit in units:
            result = self._plan_push(unit, force=force)
            if isinstance(result, Outcome):
                outcomes[unit.id] = result
            else:
                plans.append(result)

        relay_lists = self.store.fetch_lists([p.unit.id for p in plans if p.meta is not None])
        for p in plans:
            p.uploads, p.removals = plan_upload(p.fileset, relay_lists.get(p.unit.id, EMPTY))

        if dry_run:
            for p in plans:
                outcomes[p.unit.id] = Outcome(p.unit.id, "would push", self._push_summary(p))
            return [outcomes[u.id] for u in units]

        if plans:
            history = f"history/{stamp()}" if self.store.cfg.history else None
            up_files = sum(len(p.uploads or []) for p in plans)
            up_bytes = sum(
                e.size
                for p in plans
                for e in p.fileset.of_kind(KIND_FILE)
                if e.path in set(p.uploads or [])
            )
            removed = sum(len(p.removals or []) for p in plans)
            say(
                f"pushing {up_files} files ({up_bytes / MIB:.1f} MiB) from {len(plans)} units, "
                f"removing {removed}"
            )
            try:
                root = self.config.workspace.root
                self.store.put(
                    root,
                    [f"{p.unit.id}/{path}" for p in plans for path in p.uploads or []],
                    "repos",
                    backup_sub=history,
                )
                self.store.remove(
                    "repos",
                    [f"{p.unit.id}/{path}" for p in plans for path in p.removals or []],
                    backup_sub=history,
                )
                items = {}
                for p in plans:
                    items[p.unit.id] = (
                        Meta(
                            generation=uuid.uuid4().hex,
                            host=self.config.host,
                            time=now(),
                            fingerprint=p.fingerprint,
                            files=p.fileset.files,
                            bytes=p.fileset.bytes,
                        ),
                        p.fileset,
                    )
                self.store.publish(items)
            except RelayError as err:
                for p in plans:
                    outcomes[p.unit.id] = Outcome(p.unit.id, "failed", str(err))
                return [outcomes[u.id] for u in units]

            for p in plans:
                meta, fileset = items[p.unit.id]
                self.meta[p.unit.id] = meta
                self.state.save(
                    p.unit.id, UnitState(meta.generation, p.fingerprint, meta.time), fileset
                )
                outcomes[p.unit.id] = Outcome(p.unit.id, "pushed", self._push_summary(p))
        return [outcomes[u.id] for u in units]

    @staticmethod
    def _push_summary(p: _Push) -> str:
        up = sum(e.size for e in p.fileset.of_kind(KIND_FILE) if e.path in set(p.uploads or []))
        return (
            f"{len(p.uploads or [])} files up ({up / MIB:.1f} MiB), "
            f"{len(p.removals or [])} removed, {p.fileset.files} files total"
        )

    def _plan_push(self, unit: GitRepo, *, force: bool) -> Outcome | _Push:
        if why := unit.blocker():
            return Outcome(unit.id, "skipped", why)
        fileset = unit.collect()
        fingerprint = unit.fingerprint(fileset)
        limit = unit.rules.max_mb
        if limit and fileset.bytes > limit * MIB:
            size = fileset.bytes / MIB
            return Outcome(unit.id, "skipped", f"{size:.0f} MiB exceeds max_mb={limit:g}")

        state = self.state.load(unit.id)
        meta = self.meta.get(unit.id)
        if meta is not None:
            if state is None:
                if fingerprint == meta.fingerprint:
                    self._adopt(unit.id, meta, fileset)
                    return Outcome(unit.id, "adopted", "relay already holds this state")
                if not force:
                    return Outcome(
                        unit.id,
                        "conflict",
                        f"relay holds {meta.host}'s copy from {meta.time} and this host has "
                        "no baseline; pull first, or push --force",
                    )
            elif state.generation != meta.generation and not force:
                return Outcome(
                    unit.id,
                    "conflict",
                    f"{meta.host} pushed at {meta.time} since the last sync; pull first, "
                    "or push --force",
                )
            elif state.generation == meta.generation and fingerprint == state.fingerprint:
                return Outcome(unit.id, "unchanged")
        return _Push(unit, fileset, fingerprint, meta)

    # --- pull ---

    def pull(
        self,
        unit_ids: list[str],
        *,
        take_relay: bool = False,
        keep_local: bool = False,
        dry_run: bool = False,
    ) -> list[Outcome]:
        """Pull every given unit from the relay, transferring in one batch.

        Args:
            unit_ids: Units known to the relay.
            take_relay: Overwrite local changes without setting them aside and
                make the local copy an exact mirror of the tracked set.
            keep_local: Skip units with local changes instead.
            dry_run: Only report.

        Returns:
            One outcome per unit, in order.
        """
        if take_relay and keep_local:
            raise UsageError("--take-relay and --keep-local exclude each other")
        outcomes: dict[str, Outcome] = {}
        plans: list[_Pull] = []
        for uid in unit_ids:
            result = self._plan_pull(uid, take_relay=take_relay, keep_local=keep_local)
            if isinstance(result, Outcome):
                outcomes[uid] = result
            else:
                plans.append(result)

        relay_lists = self.store.fetch_lists([p.unit.id for p in plans])
        for p in plans:
            p.relay = relay_lists.get(p.unit.id, EMPTY)
            local = p.fileset.index() if p.fileset is not None else {}
            p.downloads = [
                e.path for e in p.relay.of_kind(KIND_FILE) if not e.same_content(local.get(e.path))
            ]
            stale = set(p.previous.paths)
            if p.take_relay and p.fileset is not None:
                stale |= set(p.fileset.paths)
            p.deletions = sorted(stale - set(p.relay.paths))

        if dry_run:
            for p in plans:
                outcomes[p.unit.id] = Outcome(p.unit.id, "would pull", self._pull_summary(p))
            return [outcomes[u] for u in unit_ids]

        if plans:
            down_files = sum(len(p.downloads or []) for p in plans)
            down_bytes = sum(
                e.size
                for p in plans
                for e in (p.relay or EMPTY).of_kind(KIND_FILE)
                if e.path in set(p.downloads or [])
            )
            aside = sum(1 for p in plans if p.set_aside)
            say(
                f"pulling {down_files} files ({down_bytes / MIB:.1f} MiB) into {len(plans)} units"
                + (f", setting {aside} local copies aside first" if aside else "")
            )
            try:
                for p in plans:
                    if p.set_aside and p.fileset is not None:
                        self.store.put(
                            p.unit.root, [e.path for e in p.fileset.of_kind(KIND_FILE)], p.set_aside
                        )
                self.store.get(
                    "repos",
                    [f"{p.unit.id}/{path}" for p in plans for path in p.downloads or []],
                    self.config.workspace.root,
                )
            except RelayError as err:
                for p in plans:
                    outcomes[p.unit.id] = Outcome(p.unit.id, "failed", str(err))
                return [outcomes[u] for u in unit_ids]

            for p in plans:
                assert p.relay is not None
                p.unit.root.mkdir(parents=True, exist_ok=True)
                prune(p.unit.root, p.deletions or [])
                materialize(p.unit.root, p.relay, set(p.downloads or []))
                self.state.save(
                    p.unit.id, UnitState(p.meta.generation, p.meta.fingerprint, now()), p.relay
                )
                summary = self._pull_summary(p)
                if p.unit.fingerprint(p.unit.collect()) != p.meta.fingerprint:
                    summary += "; local copy has extra files on top (push pending)"
                outcomes[p.unit.id] = Outcome(p.unit.id, "pulled", summary)
        return [outcomes[u] for u in unit_ids]

    @staticmethod
    def _pull_summary(p: _Pull) -> str:
        assert p.relay is not None
        wanted = set(p.downloads or [])
        down = sum(e.size for e in p.relay.of_kind(KIND_FILE) if e.path in wanted)
        text = (
            f"{len(wanted)} files down ({down / MIB:.1f} MiB), "
            f"{len(p.deletions or [])} removed, {p.relay.files} files total"
        )
        if p.set_aside:
            text += f", local copy set aside under {p.set_aside}"
        return text

    def _plan_pull(self, unit_id: str, *, take_relay: bool, keep_local: bool) -> Outcome | _Pull:
        meta = self.meta[unit_id]
        unit = unit_for(self.config, unit_id)
        state = self.state.load(unit_id)
        fileset = fingerprint = None
        if unit.exists():
            if why := unit.blocker():
                return Outcome(unit_id, "skipped", why)
            fileset = unit.collect()
            fingerprint = unit.fingerprint(fileset)

        if state is not None and state.generation == meta.generation:
            if fingerprint == state.fingerprint:
                return Outcome(unit_id, "up to date")
            return Outcome(unit_id, "up to date", "local changes only; push them")

        set_aside = None
        baseline = state.fingerprint if state else None
        if fileset is not None and fingerprint != baseline:
            if fingerprint == meta.fingerprint:
                self._adopt(unit_id, meta, fileset)
                return Outcome(unit_id, "adopted", "local copy already matches the relay")
            if keep_local:
                return Outcome(unit_id, "skipped", "local changes kept (--keep-local)")
            if not take_relay:
                set_aside = f"conflicts/{self.config.host}/{unit_id}/{stamp()}"

        previous = self.state.fileset(unit_id) or EMPTY
        return _Pull(unit, meta, fileset, previous, take_relay, set_aside)

    # --- status ---

    def status(self, units: list[GitRepo]) -> list[UnitStatus]:
        """Status of every local unit and every unit on the relay.

        Args:
            units: Locally discovered units.

        Returns:
            Rows sorted by unit id.
        """
        local = {u.id: u for u in units}
        ids = sorted(set(local) | {uid for uid in self.meta if self.config.workspace.selects(uid)})
        return [self._status_one(uid, local.get(uid)) for uid in ids]

    def _status_one(self, unit_id: str, unit: GitRepo | None) -> UnitStatus:
        meta = self.meta.get(unit_id)
        state = self.state.load(unit_id)
        relay_host = meta.host if meta else None
        relay_time = meta.time if meta else None

        if unit is None:
            return UnitStatus(unit_id, "missing", relay_host, relay_time, "not local")
        if why := unit.blocker():
            return UnitStatus(unit_id, why, relay_host, relay_time, "blocked")

        fingerprint = unit.fingerprint(unit.collect())
        if meta is None:
            return UnitStatus(unit_id, "changed", None, None, "never pushed")
        if state is None:
            if fingerprint == meta.fingerprint:
                return UnitStatus(unit_id, "clean", relay_host, relay_time, "unadopted")
            return UnitStatus(unit_id, "changed", relay_host, relay_time, "diverged")

        local_changed = fingerprint != state.fingerprint
        relay_newer = meta.generation != state.generation
        local = "changed" if local_changed else "clean"
        if local_changed and relay_newer:
            return UnitStatus(unit_id, local, relay_host, relay_time, "conflict")
        if local_changed:
            return UnitStatus(unit_id, local, relay_host, relay_time, "push pending")
        if relay_newer:
            return UnitStatus(unit_id, local, relay_host, relay_time, "pull pending")
        return UnitStatus(unit_id, local, relay_host, relay_time, "in sync")


def local_units(config: Config) -> tuple[list[GitRepo], list[str]]:
    """Discover the local units.

    Args:
        config: Parsed config.

    Returns:
        Units and the non-repository directories at repository depth.
    """
    return discover(config)
