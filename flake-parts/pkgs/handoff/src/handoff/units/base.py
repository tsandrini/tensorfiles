"""The unit protocol."""

from __future__ import annotations

from pathlib import Path
from typing import Protocol

from handoff.fileset import FileSet


class Unit(Protocol):
    """One synchronised thing.

    Attributes:
        id: Stable identifier shared by every host, e.g. `meteopress/radar-kit-fu`;
            also the unit's relative path below the workspace root and on the relay.
        root: Local directory of the unit (may not exist yet before the first pull).
    """

    id: str
    root: Path

    def collect(self) -> FileSet:
        """List what travels, honouring the unit's rules."""
        ...

    def fingerprint(self, fileset: FileSet) -> str:
        """Content fingerprint used to detect local changes since the last sync."""
        ...

    def blocker(self) -> str | None:
        """Why the unit must not be touched right now, `None` when it is safe."""
        ...
