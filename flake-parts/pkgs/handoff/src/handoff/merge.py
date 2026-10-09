"""Merge units: state both hosts write to, reconciled per file instead of per unit.

Claude Code's runtime state is the first such unit. Both machines append to
their own session files, so there is no canonical copy to protect with a
generation; instead every file is reconciled on its own:

- a file is *append-only compatible* with another when the shorter one is a
  byte prefix of the longer one, which is what one session file looks like
  before and after more turns;
- push uploads new and append-compatible longer files, pull downloads them
  the other way round, and a file that diverged on both sides is never
  overwritten: the other side's version goes to a conflicts directory;
- deletions never propagate, a pull only looks at what others pushed since
  this host last pulled (`--all` reconciles everything), and the prompt
  history is merged as a union of lines;
- a session the local registry reports as running is never touched by a
  pull, and its relay entry says where it is live.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
from collections.abc import Iterable
from dataclasses import asdict, dataclass, replace
from pathlib import Path

from handoff.config import ClaudeState, Config
from handoff.engine import MIB, now, say, stamp
from handoff.errors import RelayError
from handoff.state import StateStore
from handoff.store import Store

NAME = "claude"
HISTORY = "history.jsonl"
CHUNK = 1 << 20


@dataclass(frozen=True)
class MergeEntry:
    """One file of a merge unit, locally or on the relay.

    Attributes:
        path: Path relative to the unit root.
        size: Byte size.
        mtime: Modification time in nanoseconds.
        mode: Permission bits.
        hash: Hex SHA-256 of the content.
        pushed_at: ISO time of the push that stored this version (relay only).
        host: Host that pushed it (relay only).
        live: Whether that host reported the owning session as running.
        serial: Relay serial of the push that stored this version; serials
            grow by one per publish, so "since my last pull" is a comparison
            that does not depend on the hosts' clocks.
    """

    path: str
    size: int
    mtime: int
    mode: int
    hash: str
    pushed_at: str = ""
    host: str = ""
    live: bool = False
    serial: int = 0


def dump_entries(entries: Iterable[MergeEntry]) -> str:
    """Serialise entries for the relay.

    Args:
        entries: Entries to store.

    Returns:
        Compact JSON.
    """
    return json.dumps({"entries": [asdict(e) for e in entries]}, separators=(",", ":"))


def load_entries(text: str | None) -> dict[str, MergeEntry]:
    """Parse `dump_entries` output.

    Args:
        text: JSON, or `None` for an empty relay.

    Returns:
        Entries keyed by path.
    """
    if not text:
        return {}
    return {e["path"]: MergeEntry(**e) for e in json.loads(text)["entries"]}


def sha256_prefix(path: Path, length: int | None = None) -> str:
    """SHA-256 of a file, or of its first `length` bytes.

    Args:
        path: File to hash.
        length: Byte count, the whole file when `None`.

    Returns:
        Hex digest.
    """
    h = hashlib.sha256()
    remaining = length
    with path.open("rb") as f:
        while remaining is None or remaining > 0:
            chunk = f.read(CHUNK if remaining is None else min(CHUNK, remaining))
            if not chunk:
                break
            h.update(chunk)
            if remaining is not None:
                remaining -= len(chunk)
    return h.hexdigest()


def is_prefix(short: Path, long: Path, length: int) -> bool:
    """Whether the first `length` bytes of two files are identical.

    Args:
        short: File expected to be the prefix.
        long: File expected to extend it.
        length: Number of bytes to compare.

    Returns:
        `True` when they match.
    """
    with short.open("rb") as a, long.open("rb") as b:
        remaining = length
        while remaining > 0:
            n = min(CHUNK, remaining)
            x, y = a.read(n), b.read(n)
            if not x or x != y:
                return False
            remaining -= len(x)
    return True


def live_sessions(root: Path) -> set[str]:
    """Session ids the local registry reports as running.

    Args:
        root: The `~/.claude` directory.

    Returns:
        Session ids whose process is alive.
    """
    ids = set()
    registry = root / "sessions"
    if not registry.is_dir():
        return ids
    for entry in registry.glob("*.json"):
        try:
            data = json.loads(entry.read_text())
            pid = int(data["pid"])
            session = str(data["sessionId"])
        except (OSError, ValueError, KeyError, TypeError):
            continue
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            continue
        except PermissionError:
            pass
        ids.add(session)
    return ids


def merge_history(texts: Iterable[str]) -> str:
    """Union of prompt-history files, ordered by timestamp.

    Args:
        texts: Contents of `history.jsonl` files.

    Returns:
        The merged file content.
    """
    seen: dict[str, int] = {}
    for text in texts:
        for line in text.splitlines():
            if not line.strip() or line in seen:
                continue
            try:
                ts = int(json.loads(line).get("timestamp", 0))
            except (ValueError, AttributeError):
                ts = 0
            seen[line] = ts
    ordered = sorted(seen.items(), key=lambda kv: kv[1])
    return "".join(line + "\n" for line, _ in ordered)


@dataclass(frozen=True)
class MergeOutcome:
    """Summary of one merge-unit operation.

    Attributes:
        uploaded: Files sent to the relay.
        downloaded: Files taken from the relay.
        conflicts: Paths whose other version went to a conflicts directory.
        skipped_live: Paths left alone because their session runs here.
        merged_history: Whether the prompt history changed by merging.
        failed: Error message when the transfer failed, else empty.
    """

    uploaded: list[str]
    downloaded: list[str]
    conflicts: list[str]
    skipped_live: list[str]
    merged_history: bool = False
    failed: str = ""

    def summary(self, verb: str) -> str:
        """One-line report.

        Args:
            verb: `pushed` or `pulled`.

        Returns:
            The line.
        """
        if self.failed:
            return f"{NAME}  failed: {self.failed}"
        n = len(self.uploaded) if "push" in verb else len(self.downloaded)
        parts = [f"{n} files"]
        if self.merged_history:
            parts.append("history merged")
        if self.conflicts:
            parts.append(f"{len(self.conflicts)} diverged (see conflicts)")
        if self.skipped_live:
            parts.append(f"{len(self.skipped_live)} live here, left alone")
        return f"{NAME}  {verb}: " + ", ".join(parts)

    @property
    def problem(self) -> bool:
        """Whether the exit code should be non-zero."""
        return bool(self.failed or self.conflicts)


@dataclass(frozen=True)
class MergeStatus:
    """What `status` reports for a merge unit.

    Attributes:
        local: Number of local files.
        relay: Number of relay files.
        to_push: New or extended local files.
        to_pull: Relay files others pushed since the last pull.
        diverged: Files that differ on both sides without a prefix relation.
        live_elsewhere: Session ids reported live on another host.
    """

    local: int
    relay: int
    to_push: int
    to_pull: int
    diverged: int
    live_elsewhere: list[str]


class MergeEngine:
    """Push/pull/status of a merge unit against the relay."""

    def __init__(self, config: Config, cfg: ClaudeState, store: Store, state: StateStore) -> None:
        """Bind config, store and state.

        Args:
            config: Parsed config (host name, workspace are not used).
            cfg: The unit's settings.
            store: Relay to talk to.
            state: Per-host state for that relay.
        """
        self.config = config
        self.cfg = cfg
        self.store = store
        self.state = state
        self.persisted = state.load_merge(NAME)
        self.hashes: dict[str, list] = self.persisted.get("hashes", {})

    # --- local side ---

    def _hash(self, rel: str, st: os.stat_result) -> str:
        cached = self.hashes.get(rel)
        if cached and cached[0] == st.st_size and cached[1] == st.st_mtime_ns:
            return cached[2]
        digest = sha256_prefix(self.cfg.root / rel)
        self.hashes[rel] = [st.st_size, st.st_mtime_ns, digest]
        return digest

    def collect(self) -> dict[str, MergeEntry]:
        """Local files that travel, with cached content hashes.

        Returns:
            Entries keyed by path.
        """
        root = self.cfg.root
        entries = {}
        if not root.is_dir():
            return entries
        for dirpath, dirnames, filenames in os.walk(root):
            rel_dir = Path(dirpath).relative_to(root).as_posix()
            if rel_dir == self.cfg.conflicts_dir:
                dirnames[:] = []
                continue
            for name in filenames:
                rel = name if rel_dir == "." else f"{rel_dir}/{name}"
                if not self.cfg.selects(rel):
                    continue
                p = root / rel
                try:
                    st = p.lstat()
                except OSError:
                    continue
                if not p.is_file() or p.is_symlink():
                    continue
                entries[rel] = MergeEntry(
                    rel, st.st_size, st.st_mtime_ns, st.st_mode & 0o7777, self._hash(rel, st)
                )
        return entries

    def _is_live(self, rel: str, live: set[str]) -> bool:
        return any(session in rel for session in live)

    def _save(self, **changes: object) -> None:
        self.persisted.update(changes)
        self.persisted["hashes"] = {
            k: v for k, v in self.hashes.items() if (self.cfg.root / k).exists()
        }
        self.state.save_merge(NAME, self.persisted)

    # --- relay side ---

    def fetch(self) -> tuple[dict, dict[str, MergeEntry]]:
        """The relay's stamp and entries.

        Returns:
            Stamp (empty when never pushed) and entries keyed by path.
        """
        stamp_data, listing = self.store.fetch_merge(NAME)
        return stamp_data or {}, load_entries(listing)

    def _publish(self, entries: dict[str, MergeEntry], changed: set[str], seen: dict) -> None:
        # re-read right before writing: another host may have pushed meanwhile
        fresh_stamp, fresh = self.fetch()
        if fresh_stamp.get("generation") != seen.get("generation"):
            for path, entry in fresh.items():
                if path not in changed:
                    entries[path] = entry
        serial = int(fresh_stamp.get("serial", 0)) + 1
        for path in changed:
            entries[path] = replace(entries[path], serial=serial)
        stamp_data = {
            "generation": hashlib.sha256(os.urandom(16)).hexdigest()[:32],
            "serial": serial,
            "host": self.config.host,
            "time": now(),
            "files": len(entries),
        }
        self.store.publish_merge(NAME, stamp_data, dump_entries(entries.values()))

    def _conflict_sub(self) -> str:
        return f"conflicts/{self.config.host}/{NAME}/{stamp()}"

    # --- push ---

    def push(self, *, dry_run: bool = False) -> MergeOutcome:
        """Send new and extended local files to the relay.

        Args:
            dry_run: Only report.

        Returns:
            What happened.
        """
        say(f"{NAME}: scanning local state")
        local = self.collect()
        live = live_sessions(self.cfg.root)
        stamp_data, relay = self.fetch()
        uploads: list[str] = []
        conflicts: list[str] = []
        updates: dict[str, MergeEntry] = dict(relay)
        changed: set[str] = set()
        pushed_at = now()
        merged_history = False

        if HISTORY in local and HISTORY in relay and local[HISTORY].hash != relay[HISTORY].hash:
            merged_history = self._merge_history_from_relay(local, dry_run=dry_run)

        for rel, entry in sorted(local.items()):
            is_live = self._is_live(rel, live)
            remote = relay.get(rel)
            if remote is None:
                uploads.append(rel)
            elif remote.size == entry.size and remote.hash == entry.hash:
                if remote.live != is_live:
                    # liveness only: keep the stored serial, nobody needs to re-pull
                    updates[rel] = replace(remote, live=is_live, host=self.config.host)
                continue
            elif rel == HISTORY or (
                entry.size > remote.size
                and sha256_prefix(self.cfg.root / rel, remote.size) == remote.hash
            ):
                uploads.append(rel)  # the history was just merged, so it is a superset
            else:
                conflicts.append(rel)
                continue
            updates[rel] = replace(entry, pushed_at=pushed_at, host=self.config.host, live=is_live)
            changed.add(rel)

        up_bytes = sum(local[p].size for p in uploads)
        say(
            f"{NAME}: {len(uploads)} files to push ({up_bytes / MIB:.1f} MiB), "
            f"{len(conflicts)} diverged"
        )
        if dry_run:
            return MergeOutcome(uploads, [], conflicts, [], merged_history)

        try:
            # live session files keep growing: upload a snapshot whose hash we know
            live_uploads = [p for p in uploads if self._is_live(p, live)]
            snapshot = self.store.tmp / "live-snapshot"
            for rel in live_uploads:
                dst = snapshot / rel
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(self.cfg.root / rel, dst)
                st = dst.stat()
                updates[rel] = replace(
                    updates[rel], size=st.st_size, mtime=st.st_mtime_ns, hash=sha256_prefix(dst)
                )
            self.store.put(
                self.cfg.root, [p for p in uploads if p not in live_uploads], f"state/{NAME}"
            )
            self.store.put(snapshot, live_uploads, f"state/{NAME}")
            if conflicts:
                self.store.put(self.cfg.root, conflicts, self._conflict_sub())
            if uploads or updates != relay:
                self._publish(updates, changed, stamp_data)
        except RelayError as err:
            return MergeOutcome([], [], conflicts, [], merged_history, failed=str(err))

        self._save(last_push=pushed_at)
        return MergeOutcome(uploads, [], conflicts, [], merged_history)

    def _merge_history_from_relay(self, local: dict[str, MergeEntry], *, dry_run: bool) -> bool:
        staging = self.store.tmp / "history-merge"
        self.store.get(f"state/{NAME}", [HISTORY], staging)
        remote_text = (staging / HISTORY).read_text()
        local_path = self.cfg.root / HISTORY
        merged = merge_history([local_path.read_text(), remote_text])
        if merged == local_path.read_text():
            return False
        if not dry_run:
            tmp = local_path.with_suffix(".jsonl.handoff-tmp")
            tmp.write_text(merged)
            tmp.replace(local_path)
            st = local_path.stat()
            self.hashes.pop(HISTORY, None)
            local[HISTORY] = MergeEntry(
                HISTORY, st.st_size, st.st_mtime_ns, st.st_mode & 0o7777, self._hash(HISTORY, st)
            )
        return True

    # --- pull ---

    def pull(self, *, everything: bool = False, dry_run: bool = False) -> MergeOutcome:
        """Take what other hosts pushed since the last pull.

        Args:
            everything: Consider every relay entry, not only recent pushes
                (fresh machine, or deliberately resurrecting old sessions).
            dry_run: Only report.

        Returns:
            What happened.
        """
        say(f"{NAME}: scanning local state")
        local = self.collect()
        live = live_sessions(self.cfg.root)
        _, relay = self.fetch()
        last_serial = self.persisted.get("last_serial")
        everything = everything or last_serial is None
        downloads: list[str] = []
        conflicts: list[str] = []
        skipped: list[str] = []
        history_merge = False

        for rel, remote in sorted(relay.items()):
            if remote.host == self.config.host and not (everything and rel not in local):
                continue
            if not everything and remote.serial <= last_serial:
                continue
            if self._is_live(rel, live):
                skipped.append(rel)
                continue
            mine = local.get(rel)
            if rel == HISTORY:
                history_merge = mine is None or mine.hash != remote.hash
                if history_merge:
                    downloads.append(rel)
                continue
            if mine is None or remote.size > mine.size:
                downloads.append(rel)  # verified as an extension after download
            elif mine.size == remote.size and mine.hash == remote.hash:
                continue
            elif sha256_prefix(self.cfg.root / rel, remote.size) == remote.hash:
                continue  # local is ahead: push pending
            else:
                conflicts.append(rel)
                downloads.append(rel)

        down_bytes = sum(relay[p].size for p in downloads)
        say(
            f"{NAME}: {len(downloads)} files to pull ({down_bytes / MIB:.1f} MiB), "
            f"{len(skipped)} live here"
        )
        if dry_run:
            return MergeOutcome([], downloads, conflicts, skipped, history_merge)

        staging = self.store.tmp / "pull-stage"
        try:
            self.store.get(f"state/{NAME}", downloads, staging)
        except RelayError as err:
            return MergeOutcome([], [], [], skipped, failed=str(err))

        taken: list[str] = []
        conflict_root = self.cfg.root / self.cfg.conflicts_dir
        for rel in downloads:
            src = staging / rel
            dst = self.cfg.root / rel
            remote = relay[rel]
            if not src.exists():
                continue
            if rel == HISTORY:
                merged = merge_history([dst.read_text() if dst.exists() else "", src.read_text()])
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_text(merged)
                self.hashes.pop(rel, None)
                taken.append(rel)
                continue
            mine = local.get(rel)
            diverged = rel in conflicts or (mine is not None and not is_prefix(dst, src, mine.size))
            if diverged:
                if rel not in conflicts:
                    conflicts.append(rel)
                aside = conflict_root / remote.host / rel
                aside.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(src, aside)
                continue
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(src, dst)
            dst.chmod(remote.mode)
            os.utime(dst, ns=(remote.mtime, remote.mtime))
            self.hashes[rel] = [remote.size, remote.mtime, remote.hash]
            taken.append(rel)

        newest = max((e.serial for e in relay.values()), default=last_serial or 0)
        self._save(last_serial=newest)
        return MergeOutcome([], taken, conflicts, skipped, history_merge)

    # --- status ---

    def status(self) -> MergeStatus:
        """Compare local state with the relay without transferring anything.

        Returns:
            The counts.
        """
        local = self.collect()
        live = live_sessions(self.cfg.root)
        _, relay = self.fetch()
        last_serial = self.persisted.get("last_serial")
        to_push = diverged = to_pull = 0
        for rel, entry in local.items():
            remote = relay.get(rel)
            if remote is None:
                to_push += 1
            elif remote.size == entry.size and remote.hash == entry.hash:
                continue
            elif (
                entry.size > remote.size
                and (sha256_prefix(self.cfg.root / rel, remote.size) == remote.hash)
            ) or rel == HISTORY:
                to_push += 1
            else:
                diverged += 1
        for rel, remote in relay.items():
            if remote.host == self.config.host:
                continue
            if last_serial is None or remote.serial > last_serial:
                mine = local.get(rel)
                if mine is None or mine.hash != remote.hash:
                    to_pull += 1
        live_elsewhere = sorted(
            {
                part
                for e in relay.values()
                if e.live and e.host != self.config.host
                for part in e.path.split("/")
                if len(part) == 36 and part.count("-") == 4
            }
            - live
        )
        self._save()
        return MergeStatus(len(local), len(relay), to_push, to_pull, diverged, live_elsewhere)
