"""Per-host sync state: which relay generation each unit was last synced with."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from handoff.fileset import FileSet


@dataclass(frozen=True)
class UnitState:
    """Baseline recorded after the last successful push or pull of a unit.

    Attributes:
        generation: Relay generation the local copy corresponds to.
        fingerprint: Fingerprint the local copy is expected to have.
        synced_at: ISO timestamp of that sync.
    """

    generation: str
    fingerprint: str
    synced_at: str


class StateStore:
    """State files under `<state_dir>/<relay>/units/<unit id>.{json,files}`."""

    def __init__(self, state_dir: Path, relay_name: str) -> None:
        """Bind the store to one relay.

        Args:
            state_dir: Root state directory.
            relay_name: Relay the generations belong to.
        """
        self.dir = state_dir / relay_name / "units"

    def _base(self, unit_id: str) -> Path:
        return self.dir / unit_id

    def load(self, unit_id: str) -> UnitState | None:
        """Baseline of a unit, `None` if it was never synced with this relay.

        Args:
            unit_id: Unit id.

        Returns:
            The baseline or `None`.
        """
        path = self._base(unit_id).with_suffix(".json")
        if not path.exists():
            return None
        return UnitState(**json.loads(path.read_text()))

    def fileset(self, unit_id: str) -> FileSet | None:
        """What travelled at the last sync (for propagating deletions).

        Args:
            unit_id: Unit id.

        Returns:
            The file set, `None` if unknown.
        """
        return FileSet.load(self._base(unit_id).with_suffix(".files"))

    def save(self, unit_id: str, state: UnitState, fileset: FileSet) -> None:
        """Record a new baseline.

        Args:
            unit_id: Unit id.
            state: The baseline.
            fileset: What travelled.
        """
        base = self._base(unit_id)
        base.parent.mkdir(parents=True, exist_ok=True)
        fileset.dump(base.with_suffix(".files"))
        tmp = base.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(asdict(state), indent=2) + "\n")
        tmp.replace(base.with_suffix(".json"))
