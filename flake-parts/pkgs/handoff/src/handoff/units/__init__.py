"""Units: the things that travel as one piece (a git repository, later Claude state).

A unit knows what to send (`collect`), how to tell whether it changed
(`fingerprint`) and whether it is safe to touch right now (`blocker`). The
engine is unit-agnostic beyond that.
"""

from handoff.units.base import Unit
from handoff.units.git import GitRepo, discover

__all__ = ["GitRepo", "Unit", "discover"]
