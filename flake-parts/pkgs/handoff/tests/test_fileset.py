"""File-set collection and fingerprints."""

from __future__ import annotations

from pathlib import Path

from handoff.config import Rules
from handoff.fileset import collect, excluded
from handoff.units.git import GitRepo

from .conftest import git, make_repo, write


def test_excluded_patterns() -> None:
    patterns = ("node_modules", "result-*", "data/raw")
    assert excluded("a/node_modules/b.js", patterns)
    assert excluded("result-bin", patterns)
    assert excluded("data/raw", patterns)
    assert not excluded("data/rawr", patterns)
    assert not excluded("src/main.rs", patterns)


def test_collect_expands_and_excludes(tmp_path: Path) -> None:
    write(tmp_path, "a/b.txt", "b")
    write(tmp_path, "a/node_modules/x.js", "x")
    write(tmp_path, "c.txt", "c")
    (tmp_path / "link").symlink_to("c.txt")
    fs = collect(tmp_path, ["a", "c.txt", "link", "missing"], ("node_modules",))
    assert fs.paths == ["a", "a/b.txt", "c.txt", "link"]
    assert {e.kind for e in fs.entries} == {"d", "f", "l"}
    assert fs.files == 3
    assert fs.bytes == 2


def test_git_unit_file_set(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "b/r", {"src/main.py": "x\n", ".gitignore": "*.log\n.env\nbuild/\n"})
    write(repo, "untracked.txt", "u")
    write(repo, "noise.log", "l")
    write(repo, ".env", "SECRET=1")
    write(repo, "build/out.bin", "o")
    write(repo, "node_modules/pkg/index.js", "j")
    unit = GitRepo("b/r", repo, Rules(keep_ignored=(".env",)))
    paths = unit.collect().paths
    assert "src/main.py" in paths
    assert "untracked.txt" in paths
    assert ".env" in paths
    assert ".git/HEAD" in paths
    assert ".git/objects" in paths
    assert "noise.log" not in paths
    assert "build/out.bin" not in paths
    assert not any(p.startswith("node_modules") for p in paths)


def test_fingerprint_ignores_stat_refresh_but_sees_staging(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "b/r")
    unit = GitRepo("b/r", repo, Rules())
    before = unit.fingerprint(unit.collect())
    # touching the index without changing what is staged must not count
    (repo / ".git/index").touch()
    git(repo, "status", "--porcelain")
    assert unit.fingerprint(unit.collect()) == before
    write(repo, "new.txt", "n")
    git(repo, "add", "new.txt")
    assert unit.fingerprint(unit.collect()) != before


def test_blocker(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "b/r")
    unit = GitRepo("b/r", repo, Rules())
    assert unit.blocker() is None
    (repo / ".git/index.lock").touch()
    assert unit.blocker() == "git is running (index.lock)"
