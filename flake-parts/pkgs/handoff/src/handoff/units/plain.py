"""Plain directories (notes, scratch folders) as units: everything travels."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from handoff.config import Rules
from handoff.fileset import FileSet, collect


@dataclass(frozen=True)
class PlainDir:
    """A directory without git: every file travels, minus the always-excludes.

    Attributes:
        id: `<bundle>/<dir>` relative to the workspace root.
        root: Local directory.
        rules: What travels (`keep_ignored` is meaningless here).
    """

    id: str
    root: Path
    rules: Rules
    kind: str = "plain"

    def exists(self) -> bool:
        """Whether the directory is present locally."""
        return self.root.is_dir()

    def collect(self) -> FileSet:
        """Every entry below the directory, honouring the always-exclude patterns.

        Returns:
            The file set.
        """
        if not self.exists():
            return FileSet(())
        names = sorted(child.name for child in self.root.iterdir())
        return collect(self.root, names, self.rules.always_exclude)

    def fingerprint(self, fileset: FileSet) -> str:
        """Stat-based digest.

        Args:
            fileset: Output of `collect`.

        Returns:
            Hex SHA-256.
        """
        return fileset.digest()

    def blocker(self) -> str | None:
        """Plain directories are always safe to copy.

        Returns:
            `None`.
        """
        return None
