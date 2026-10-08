"""The relay: a dumb file store driven through rclone, optionally encrypted.

Layout below the relay path:

    repos/<unit id>/<path>                  canonical copy (regular files only)
    meta/<unit id>.json                     generation stamp of that copy (`Meta`)
    meta/<unit id>.files                    `FileSet` JSON: everything the copy
                                            holds, incl. dirs, links, modes, mtimes
    history/<time>/<unit id>/<path>         files a push overwrote or removed
    conflicts/<host>/<unit id>/<time>/      local copies a pull set aside

rclone is configured through environment variables only, so no config file
is written and the crypt password never appears on a command line. With
`crypt`, content and every path segment are encrypted client-side.
"""

from __future__ import annotations

import json
import logging
import os
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

from handoff.config import Relay
from handoff.errors import RelayError
from handoff.fileset import FileSet

log = logging.getLogger("handoff")

BASE_REMOTE = "handoffbase"
CRYPT_REMOTE = "handoffcrypt"

# rclone exit code for "directory not found" on the source
EXIT_NOT_FOUND = 3


@dataclass(frozen=True)
class Meta:
    """Generation stamp of a unit's canonical copy.

    Attributes:
        generation: Opaque id, new on every push.
        host: Host that pushed it.
        time: ISO timestamp of the push.
        fingerprint: Fingerprint of the pushed state.
        files: Number of files pushed.
        bytes: Total size of the pushed regular files.
        kind: `"git"` or `"plain"` (older stamps without it are git).
    """

    generation: str
    host: str
    time: str
    fingerprint: str
    files: int
    bytes: int
    kind: str = "git"

    @classmethod
    def from_json(cls, text: str) -> Meta:
        """Parse a `meta/<unit>.json`.

        Args:
            text: JSON document.

        Returns:
            The stamp.
        """
        data = json.loads(text)
        return cls(**{k: data[k] for k in cls.__dataclass_fields__ if k in data})


def obscure(secret: str) -> str:
    """Reversibly obscure a password the way rclone expects it in its config.

    Args:
        secret: Plain password.

    Returns:
        The obscured form.
    """
    proc = subprocess.run(
        ["rclone", "obscure", "-"], input=secret, capture_output=True, text=True, check=True
    )
    return proc.stdout.strip()


class Store:
    """rclone-backed access to one relay."""

    def __init__(self, cfg: Relay, tmp: Path) -> None:
        """Bind to a relay.

        Args:
            cfg: Relay config.
            tmp: Scratch directory for lists and downloaded metadata.
        """
        self.cfg = cfg
        self.tmp = tmp
        self._env: dict[str, str] | None = None

    # --- addressing ---

    def env(self) -> dict[str, str]:
        """Process environment defining the rclone remotes.

        Returns:
            A copy of the current environment plus the `RCLONE_CONFIG_*` keys.

        Raises:
            RelayError: The crypt password cannot be read.
        """
        if self._env is not None:
            return self._env
        env = dict(os.environ)
        env["RCLONE_CONFIG"] = os.devnull
        for key, value in self.cfg.backend.items():
            env[f"RCLONE_CONFIG_{BASE_REMOTE.upper()}_{key.upper()}"] = value
        if self.cfg.crypt is not None:
            prefix = f"RCLONE_CONFIG_{CRYPT_REMOTE.upper()}_"
            env[prefix + "TYPE"] = "crypt"
            env[prefix + "REMOTE"] = f"{BASE_REMOTE}:{self.cfg.path}"
            env[prefix + "PASSWORD"] = obscure(self._secret(self.cfg.crypt.password_file))
            if self.cfg.crypt.salt_file is not None:
                env[prefix + "PASSWORD2"] = obscure(self._secret(self.cfg.crypt.salt_file))
        self._env = env
        return env

    @staticmethod
    def _secret(path: Path) -> str:
        try:
            secret = path.read_text().strip()
        except OSError as err:
            raise RelayError(f"cannot read {path}: {err.strerror}") from err
        if not secret:
            raise RelayError(f"{path} is empty")
        return secret

    def remote(self, sub: str = "") -> str:
        """rclone address of `sub` below the relay path.

        Args:
            sub: Relative path, empty for the relay root.

        Returns:
            `remote:path`.
        """
        if self.cfg.crypt is not None:
            return f"{CRYPT_REMOTE}:{sub}"
        base = f"{BASE_REMOTE}:{self.cfg.path}"
        return f"{base}/{sub}" if sub else base

    # --- plumbing ---

    def _run(self, *args: str, ok_not_found: bool = False, progress: bool = False) -> str:
        """Run rclone.

        Args:
            args: Arguments after the program name.
            ok_not_found: Treat a missing source directory as an empty result.
            progress: Show transfer progress on stderr (a live display on a
                terminal, one stats line every 30 s otherwise) instead of
                capturing it.

        Returns:
            Standard output.

        Raises:
            RelayError: rclone failed.
        """
        verbose = log.isEnabledFor(logging.DEBUG)
        level = "INFO" if verbose else "ERROR"
        if progress and sys.stderr.isatty():
            cmd = ["rclone", *args, "--log-level", level, "--progress"]
        elif progress:
            level = "INFO" if verbose else "NOTICE"
            cmd = [
                "rclone",
                *args,
                "--log-level",
                level,
                "--stats",
                "30s",
                "--stats-one-line",
                "--stats-log-level",
                "NOTICE",
            ]
        else:
            cmd = ["rclone", *args, "--log-level", level, "--stats", "0"]
        log.debug("run: %s", " ".join(cmd))
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=None if progress else subprocess.PIPE,
            text=True,
            env=self.env(),
        )
        if verbose and proc.stderr:
            for line in proc.stderr.splitlines():
                log.debug("rclone: %s", line)
        if proc.returncode == EXIT_NOT_FOUND and ok_not_found:
            return ""
        if proc.returncode != 0:
            lines = [ln for ln in (proc.stderr or "").splitlines() if ln.strip()]
            detail = lines[-1] if lines else "see the rclone output above"
            raise RelayError(f"rclone {args[0]} exited with {proc.returncode}: {detail}")
        return proc.stdout

    def _list_file(self, name: str, paths: list[str]) -> str:
        path = self.tmp / "lists" / f"{name}.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(p + "\n" for p in paths))
        return str(path)

    def _transfer_args(self) -> list[str]:
        n = str(self.cfg.transfers)
        return ["--no-traverse", "--transfers", n, "--checkers", n]

    # --- unit contents ---

    def put(self, root: Path, paths: list[str], sub: str, *, backup_sub: str | None = None) -> None:
        """Upload files of a local directory to `sub`, overwriting.

        Args:
            root: Local directory the paths are relative to.
            paths: Relative paths of regular files.
            sub: Destination below the relay path.
            backup_sub: Where overwritten files are moved first, `None` for nowhere.
        """
        if not paths:
            return
        args = [
            "copy",
            str(root),
            self.remote(sub),
            "--files-from-raw",
            self._list_file("put", paths),
            "--ignore-times",
            *self._transfer_args(),
        ]
        if backup_sub:
            args += ["--backup-dir", self.remote(backup_sub)]
        self._run(*args, progress=True)

    def get(self, sub: str, paths: list[str], root: Path) -> None:
        """Download files from `sub` into a local directory, overwriting.

        Args:
            sub: Source below the relay path.
            paths: Relative paths of regular files.
            root: Local directory.
        """
        if not paths:
            return
        self._run(
            "copy",
            self.remote(sub),
            str(root),
            "--files-from-raw",
            self._list_file("get", paths),
            "--ignore-times",
            *self._transfer_args(),
            progress=True,
        )

    def remove(self, sub: str, paths: list[str], *, backup_sub: str | None = None) -> None:
        """Remove files below `sub`, moving them into `backup_sub` if given.

        Args:
            sub: Directory below the relay path.
            paths: Relative paths of regular files.
            backup_sub: Where the files go instead of being deleted.
        """
        if not paths:
            return
        list_file = self._list_file("remove", paths)
        if backup_sub:
            self._run(
                "move",
                self.remote(sub),
                self.remote(backup_sub),
                "--files-from-raw",
                list_file,
                *self._transfer_args(),
                progress=True,
            )
        else:
            self._run("delete", self.remote(sub), "--files-from-raw", list_file, progress=True)

    # --- metadata ---

    def fetch_meta(self) -> dict[str, Meta]:
        """Download every generation stamp in one go.

        Returns:
            Stamps keyed by unit id; empty for a relay that was never pushed to.
        """
        dest = self.tmp / "meta"
        dest.mkdir(exist_ok=True)
        self._run("copy", self.remote("meta"), str(dest), "--include", "*.json", ok_not_found=True)
        if not any(dest.rglob("*.json")):
            self._check_empty()
        stamps = {}
        for path in sorted(dest.rglob("*.json")):
            unit_id = path.relative_to(dest).with_suffix("").as_posix()
            stamps[unit_id] = Meta.from_json(path.read_text())
        return stamps

    def _check_empty(self) -> None:
        """Refuse to mistake an unreadable relay for an empty one.

        A relay written with another crypt password, or with crypt while this
        config has none (and vice versa), shows no readable `meta/`; treating
        that as empty would let a push create a second, unrelated tree.

        Raises:
            RelayError: The relay path holds files this config cannot read.
        """
        base = f"{BASE_REMOTE}:{self.cfg.path}"
        listing = self._run("lsf", base, "--max-depth", "1", ok_not_found=True).strip()
        if listing:
            raise RelayError(
                f"relay path {self.cfg.path} is not empty but holds nothing this config can "
                "read: wrong crypt password, or crypt/plaintext mismatch?"
            )

    def fetch_lists(self, unit_ids: list[str]) -> dict[str, FileSet]:
        """Download the file sets of the given units' canonical copies.

        Args:
            unit_ids: Unit ids known to the relay.

        Returns:
            File sets keyed by unit id (missing lists are left out).
        """
        if not unit_ids:
            return {}
        dest = self.tmp / "lists" / "relay"
        dest.mkdir(parents=True, exist_ok=True)
        self._run(
            "copy",
            self.remote("meta"),
            str(dest),
            "--files-from-raw",
            self._list_file("fetch", [f"{uid}.files" for uid in unit_ids]),
            "--ignore-times",
            "--no-traverse",
        )
        lists = {}
        for uid in unit_ids:
            fileset = FileSet.load(dest / f"{uid}.files")
            if fileset is not None:
                lists[uid] = fileset
        return lists

    def publish(self, items: dict[str, tuple[Meta, FileSet]]) -> None:
        """Upload stamps and file sets, in one go.

        Args:
            items: Per unit id, the new stamp and the file set it describes.
        """
        if not items:
            return
        staging = self.tmp / "publish"
        paths = []
        for uid, (meta, fileset) in items.items():
            fileset.dump(staging / "meta" / f"{uid}.files")
            (staging / "meta" / f"{uid}.json").write_text(json.dumps(asdict(meta), indent=2) + "\n")
            paths += [f"meta/{uid}.files", f"meta/{uid}.json"]
        self._run(
            "copy",
            str(staging),
            self.remote(),
            "--files-from-raw",
            self._list_file("publish", paths),
            "--ignore-times",
            "--no-traverse",
        )
