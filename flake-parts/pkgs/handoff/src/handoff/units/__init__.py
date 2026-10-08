"""Units: the things that travel as one piece (a git repository, a plain directory).

A unit knows what to send (`collect`), how to tell whether it changed
(`fingerprint`) and whether it is safe to touch right now (`blocker`). The
engine is unit-agnostic beyond that.
"""

from handoff.units.base import Unit
from handoff.units.git import GitRepo, discover, unit_for
from handoff.units.plain import PlainDir

__all__ = ["GitRepo", "PlainDir", "Unit", "discover", "unit_for"]
