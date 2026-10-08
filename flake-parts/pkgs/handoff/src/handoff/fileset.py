"""The set of files that travels for one unit, and its fingerprint."""

from __future__ import annotations

import hashlib
import json
import os
import stat
from collections.abc import Iterable, Iterator
from dataclasses import dataclass
from fnmatch import fnmatchcase
from pathlib import Path

KIND_DIR = "d"
KIND_FILE = "f"
KIND_LINK = "l"


@dataclass(frozen=True, slots=True)
class Entry:
    """One path of a file set.

    Attributes:
        path: Path relative to the unit root, `/`-separated.
        kind: `"f"` regular file, `"d"` directory, `"l"` symlink.
        size: Byte size (regular files only).
        mtime: Modification time in nanoseconds (regular files only).
        mode: Permission bits (regular files only).
        target: Link target (symlinks only).
    """

    path: str
    kind: str
    size: int = 0
    mtime: int = 0
    mode: int = 0
    target: str = ""

    def same_content(self, other: Entry | None) -> bool:
        """Whether `other` describes the same bytes, time and mode.

        Args:
            other: Entry to compare with, `None` for a missing path.

        Returns:
            `True` when nothing would have to be transferred or fixed.
        """
        return other is not None and (self.kind, self.size, self.mtime, self.mode, self.target) == (
            other.kind,
            other.size,
            other.mtime,
            other.mode,
            other.target,
        )


@dataclass(frozen=True)
class FileSet:
    """Sorted entries of a unit.

    Attributes:
        entries: Entries sorted by path (so parents precede children).
    """

    entries: tuple[Entry, ...]

    @property
    def paths(self) -> list[str]:
        """All paths, sorted."""
        return [e.path for e in self.entries]

    @property
    def bytes(self) -> int:
        """Total size of the regular files."""
        return sum(e.size for e in self.entries if e.kind == KIND_FILE)

    @property
    def files(self) -> int:
        """Number of regular files and symlinks (directories do not count)."""
        return sum(1 for e in self.entries if e.kind != KIND_DIR)

    def index(self) -> dict[str, Entry]:
        """Entries keyed by path."""
        return {e.path: e for e in self.entries}

    def of_kind(self, kind: str) -> list[Entry]:
        """Entries of one kind, in path order.

        Args:
            kind: `KIND_FILE`, `KIND_DIR` or `KIND_LINK`.

        Returns:
            The matching entries.
        """
        return [e for e in self.entries if e.kind == kind]

    def digest(self, *, skip: Iterable[str] = (), extra: Iterable[str] = ()) -> str:
        """Fingerprint of the set: paths, kinds, sizes, mtimes, modes and link targets.

        Args:
            skip: Paths left out of the fingerprint (they still travel), for
                files whose stat data churns without the content mattering.
            extra: Additional strings mixed in, for state the unit tracks
                by content rather than by stat (e.g. the git index).

        Returns:
            Hex SHA-256.
        """
        skipped = set(skip)
        h = hashlib.sha256()
        for e in self.entries:
            if e.path in skipped:
                continue
            h.update(f"{e.path}\0{e.kind}\0{e.size}\0{e.mtime}\0{e.mode}\0{e.target}\n".encode())
        for s in extra:
            h.update(b"\0extra\0")
            h.update(s.encode())
        return h.hexdigest()

    def to_json(self) -> str:
        """Serialise for the relay and the local state.

        Returns:
            Compact JSON.
        """
        rows = [[e.path, e.kind, e.size, e.mtime, e.mode, e.target] for e in self.entries]
        return json.dumps({"entries": rows}, separators=(",", ":"))

    @classmethod
    def from_json(cls, text: str) -> FileSet:
        """Parse `to_json` output.

        Args:
            text: JSON document.

        Returns:
            The file set.
        """
        rows = json.loads(text)["entries"]
        return cls(tuple(Entry(*row) for row in rows))

    def dump(self, path: Path) -> None:
        """Write `to_json` to a file, creating parents.

        Args:
            path: Destination.
        """
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(self.to_json())

    @classmethod
    def load(cls, path: Path) -> FileSet | None:
        """Read a file written by `dump`.

        Args:
            path: Source.

        Returns:
            The file set, `None` when the file does not exist.
        """
        if not path.exists():
            return None
        return cls.from_json(path.read_text())


EMPTY = FileSet(())


def excluded(rel_path: str, patterns: Iterable[str]) -> bool:
    """Whether a relative path is hit by an always-exclude pattern.

    Patterns without `/` match any single path segment (`node_modules`
    anywhere in the tree); patterns with `/` match the whole relative path.

    Args:
        rel_path: `/`-separated path relative to the unit root.
        patterns: fnmatch globs.

    Returns:
        `True` when the path (or one of its parents) is excluded.
    """
    segments = rel_path.split("/")
    for pattern in patterns:
        if "/" in pattern:
            if fnmatchcase(rel_path, pattern):
                return True
        elif any(fnmatchcase(seg, pattern) for seg in segments):
            return True
    return False


def _entry(root: Path, rel: str) -> Entry | None:
    st = os.lstat(root / rel)
    if stat.S_ISLNK(st.st_mode):
        return Entry(rel, KIND_LINK, target=str((root / rel).readlink()))
    if stat.S_ISDIR(st.st_mode):
        return Entry(rel, KIND_DIR)
    if stat.S_ISREG(st.st_mode):
        return Entry(rel, KIND_FILE, st.st_size, st.st_mtime_ns, stat.S_IMODE(st.st_mode))
    return None  # sockets, fifos: never travel


def walk(root: Path, rel: str, exclude: Iterable[str]) -> Iterator[Entry]:
    """Every entry below (and including) a directory, honouring excludes.

    Symlinks are reported but never followed.

    Args:
        root: Unit root.
        rel: Directory relative to `root`.
        exclude: Always-exclude patterns.

    Yields:
        Entries in no particular order.
    """
    patterns = tuple(exclude)
    if excluded(rel, patterns):
        return
    top = _entry(root, rel)
    if top is None:
        return
    yield top
    if top.kind != KIND_DIR:
        return
    stack = [rel]
    while stack:
        current = stack.pop()
        with os.scandir(root / current) as it:
            for child in it:
                child_rel = f"{current}/{child.name}"
                if excluded(child_rel, patterns):
                    continue
                entry = _entry(root, child_rel)
                if entry is None:
                    continue
                yield entry
                if entry.kind == KIND_DIR:
                    stack.append(child_rel)


def collect(root: Path, rels: Iterable[str], exclude: Iterable[str]) -> FileSet:
    """Build a file set from top-level relative paths, expanding directories.

    Args:
        root: Unit root.
        rels: Relative paths; directories are walked, missing paths skipped.
        exclude: Always-exclude patterns.

    Returns:
        The de-duplicated, sorted file set.
    """
    patterns = tuple(exclude)
    seen: dict[str, Entry] = {}
    for rel in rels:
        rel = rel.strip("/")
        if not rel or rel in seen or excluded(rel, patterns):
            continue
        if not (root / rel).is_symlink() and not (root / rel).exists():
            continue
        for entry in walk(root, rel, patterns):
            seen.setdefault(entry.path, entry)
    # parents of every entry must exist on the receiving side as well
    for path in list(seen):
        parts = path.split("/")
        for i in range(1, len(parts)):
            parent = "/".join(parts[:i])
            if parent not in seen:
                seen[parent] = Entry(parent, KIND_DIR)
    return FileSet(tuple(sorted(seen.values(), key=lambda e: e.path)))
