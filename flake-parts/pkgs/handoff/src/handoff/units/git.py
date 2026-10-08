"""Git repositories as units."""

from __future__ import annotations

import hashlib
import subprocess
from dataclasses import dataclass
from pathlib import Path

from handoff.config import Config, Rules
from handoff.errors import HandoffError
from handoff.fileset import FileSet, collect, excluded
from handoff.units.plain import PlainDir

# Rewritten by read-only git commands (`status` refreshes stat data, `fetch`
# rewrites FETCH_HEAD); they travel, but do not count as a local change.
VOLATILE = frozenset({".git/index", ".git/FETCH_HEAD", ".git/gitk.cache"})


def _git(repo: Path, *args: str) -> bytes:
    try:
        return subprocess.run(
            ["git", "-C", str(repo), *args],
            check=True,
            capture_output=True,
        ).stdout
    except subprocess.CalledProcessError as err:
        detail = err.stderr.decode(errors="replace").strip() or f"exit {err.returncode}"
        raise HandoffError(f"git {args[0]} failed in {repo}: {detail}") from err


@dataclass(frozen=True)
class GitRepo:
    """A git working tree together with its whole `.git` directory.

    Attributes:
        id: `<bundle>/<repo>` relative to the workspace root.
        root: Local directory.
        rules: What travels.
    """

    id: str
    root: Path
    rules: Rules
    kind: str = "git"

    @property
    def git_dir(self) -> Path:
        """`.git` of the working tree (a directory, or a file for worktrees)."""
        return self.root / ".git"

    def exists(self) -> bool:
        """Whether the repository is present locally."""
        return self.git_dir.exists()

    def collect(self) -> FileSet:
        """Everything not gitignored, the kept ignored files, and `.git` itself.

        Untracked nested repositories and submodules are walked wholesale, with
        only the always-exclude patterns applied.

        Returns:
            The file set.
        """
        out = _git(self.root, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
        rels = [p.decode() for p in out.split(b"\0") if p]
        for pattern in self.rules.keep_ignored:
            rels.extend(
                p.relative_to(self.root).as_posix()
                for p in self.root.glob(pattern)
                if not excluded(p.relative_to(self.root).as_posix(), self.rules.always_exclude)
            )
        rels.append(".git")
        return collect(self.root, rels, self.rules.always_exclude)

    def fingerprint(self, fileset: FileSet) -> str:
        """Stat-based digest, with the index tracked by content instead.

        Args:
            fileset: Output of `collect`.

        Returns:
            Hex SHA-256.
        """
        index = hashlib.sha256(_git(self.root, "ls-files", "-s", "-z")).hexdigest()
        return fileset.digest(skip=VOLATILE, extra=[f"index:{index}"])

    def blocker(self) -> str | None:
        """A git operation in progress makes the tree unsafe to copy.

        Returns:
            A short reason, or `None`.
        """
        if not self.exists():
            return None
        if self.git_dir.is_file():
            return None  # linked worktree: the real .git lives elsewhere, skip the check
        for marker, reason in (
            ("index.lock", "git is running (index.lock)"),
            ("MERGE_HEAD", "merge in progress"),
            ("rebase-merge", "rebase in progress"),
            ("rebase-apply", "rebase in progress"),
            ("CHERRY_PICK_HEAD", "cherry-pick in progress"),
        ):
            if (self.git_dir / marker).exists():
                return reason
        return None


def unit_for(config: Config, unit_id: str, kind: str | None = None) -> GitRepo | PlainDir:
    """The unit with a given id, whether or not it exists locally.

    Args:
        config: Parsed config.
        unit_id: `<bundle>/<repo>`.
        kind: `"git"` or `"plain"` as recorded on the relay; decides the type
            when the unit does not exist locally yet.

    Returns:
        The unit.
    """
    root = config.workspace.root / unit_id
    rules = config.rules_for(unit_id)
    if (root / ".git").exists():
        return GitRepo(id=unit_id, root=root, rules=rules)
    if kind == "plain" or (kind is None and root.is_dir()):
        return PlainDir(id=unit_id, root=root, rules=rules)
    return GitRepo(id=unit_id, root=root, rules=rules)


def discover(config: Config) -> list[GitRepo | PlainDir]:
    """Find the units below the workspace root.

    Every directory at repository depth is a unit: a git repository when it
    has a `.git`, a plain directory otherwise.

    Args:
        config: Parsed config.

    Returns:
        The discovered units sorted by id.
    """
    ws = config.workspace
    units: list[GitRepo | PlainDir] = []
    level = [ws.root] if ws.root.is_dir() else []
    for _ in range(ws.depth - 1):
        level = [
            child
            for parent in level
            for child in sorted(parent.iterdir())
            if child.is_dir() and not child.is_symlink() and not child.name.startswith(".")
        ]
    for parent in level:
        for child in sorted(parent.iterdir()):
            if not child.is_dir() or child.is_symlink() or child.name.startswith("."):
                continue
            unit_id = child.relative_to(ws.root).as_posix()
            if ws.selects(unit_id):
                units.append(unit_for(config, unit_id))
    return units
