"""Push, pull and status end to end through a local relay with real git and rclone."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from handoff.config import Relay, RepoOverride
from handoff.engine import local_units, select
from handoff.errors import UsageError

from .conftest import Host, git, make_repo, write

UNIT = "work/app"


def actions(outcomes: list) -> dict[str, str]:
    return {o.unit_id: o.action for o in outcomes}


def states(host: Host) -> dict[str, str]:
    return {r.unit_id: r.state for r in host.engine().status(local_units(host.config))}


def push(host: Host, **kwargs: object) -> dict[str, str]:
    return actions(host.engine().push(local_units(host.config), **kwargs))  # type: ignore[arg-type]


def pull(host: Host, **kwargs: object) -> dict[str, str]:
    engine = host.engine()
    return actions(engine.pull(sorted(engine.meta), **kwargs))  # type: ignore[arg-type]


def ls_files(repo: Path) -> str:
    return git(repo, "ls-files", "-s")


# --- select ---


def test_select_exact_and_prefix() -> None:
    known = ["a/x", "a/y", "b/z"]
    assert select([], known) == known
    assert select(["a/"], known) == ["a/x", "a/y"]
    assert select(["b/z", "a/x"], known) == ["b/z", "a/x"]
    with pytest.raises(UsageError, match="matches no unit"):
        select(["c/"], known)


# --- round trips ---


def test_push_then_pull_creates_identical_copy(alpha: Host, beta: Host) -> None:
    repo = make_repo(
        alpha.path(""), UNIT, {"src/a.py": "a\n", ".gitignore": ".env\n*.log\nnode_modules/\n"}
    )
    write(repo, "untracked.txt", "u\n")
    write(repo, ".env", "S=1\n")
    write(repo, "debug.log", "noise\n")
    write(repo, "node_modules/x/i.js", "j\n")
    write(repo, "staged.txt", "s\n")
    git(repo, "add", "staged.txt")
    write(repo, "stashed.txt", "st\n")
    git(repo, "add", "stashed.txt")
    git(repo, "stash", "-q")

    assert push(alpha) == {UNIT: "pushed"}
    assert json.loads(alpha.relay_read(f"meta/{UNIT}.json"))["host"] == "alpha"
    on_relay = alpha.relay_files(f"repos/{UNIT}")
    assert ".env" in on_relay
    assert "debug.log" not in on_relay
    assert not any(p.startswith("node_modules/") for p in on_relay)
    assert push(alpha) == {UNIT: "unchanged"}
    assert states(alpha) == {UNIT: "in sync"}

    assert pull(beta) == {UNIT: "pulled"}
    copy = beta.path(UNIT)
    assert (copy / "src/a.py").read_text() == "a\n"
    assert (copy / "untracked.txt").exists()
    assert (copy / ".env").read_text() == "S=1\n"
    assert not (copy / "debug.log").exists()
    assert ls_files(copy) == ls_files(repo)
    assert "stash@{0}" in git(copy, "stash", "list")
    assert git(copy, "status", "--porcelain") == git(repo, "status", "--porcelain")
    assert states(beta) == {UNIT: "in sync"}
    assert pull(beta) == {UNIT: "up to date"}


def test_changes_and_deletions_propagate(alpha: Host, beta: Host) -> None:
    repo = make_repo(alpha.path(""), UNIT, {"keep.txt": "k\n", "gone.txt": "g\n"})
    write(repo, "gone-dir/x.txt", "x\n")
    push(alpha)
    pull(beta)
    assert (beta.path(UNIT) / "gone-dir/x.txt").exists()

    (repo / "gone.txt").unlink()
    (repo / "gone-dir/x.txt").unlink()
    (repo / "gone-dir").rmdir()
    write(repo, "keep.txt", "k2\n")
    git(repo, "commit", "-qam", "second")
    assert push(alpha) == {UNIT: "pushed"}
    on_relay = alpha.relay_files(f"repos/{UNIT}")
    assert "gone.txt" not in on_relay
    assert not any(p.startswith("gone-dir/") for p in on_relay)
    history = alpha.relay_files("history")
    assert sum(p.endswith(f"{UNIT}/gone.txt") for p in history) == 1
    assert sum(p.endswith(f"{UNIT}/keep.txt") for p in history) == 1  # overwritten

    # a local gitignored file on beta must survive the pull untouched
    write(beta.path(UNIT), "local.log", "mine\n")
    write(beta.path(UNIT), ".gitignore", "*.log\n")
    assert states(beta) == {UNIT: "conflict"}  # .gitignore edit is a local change
    assert pull(beta, take_relay=True) == {UNIT: "pulled"}
    copy = beta.path(UNIT)
    assert not (copy / "gone.txt").exists()
    assert not (copy / "gone-dir").exists()
    assert (copy / "keep.txt").read_text() == "k2\n"
    assert (copy / "local.log").read_text() == "mine\n"
    assert git(copy, "log", "--oneline").count("\n") == 2
    # the relay had no .gitignore, so beta's went away and local.log is now a
    # plain untracked file that wants to travel
    assert states(beta) == {UNIT: "push pending"}


def test_relay_moved_on_refuses_push(alpha: Host, beta: Host) -> None:
    repo_a = make_repo(alpha.path(""), UNIT)
    push(alpha)
    pull(beta)
    write(repo_a, "a.txt", "from alpha\n")
    write(beta.path(UNIT), "b.txt", "from beta\n")
    assert push(alpha) == {UNIT: "pushed"}
    assert states(beta) == {UNIT: "conflict"}
    assert push(beta) == {UNIT: "conflict"}
    assert push(beta, force=True) == {UNIT: "pushed"}
    # alpha's copy equals its baseline, so it is simply behind; its a.txt is
    # no longer canonical but survives under history/
    assert states(alpha) == {UNIT: "pull pending"}
    assert any(p.endswith(f"{UNIT}/a.txt") for p in alpha.relay_files("history"))
    assert pull(alpha) == {UNIT: "pulled"}
    assert not (alpha.path(UNIT) / "a.txt").exists()
    assert (alpha.path(UNIT) / "b.txt").exists()


def test_pull_sets_local_changes_aside(alpha: Host, beta: Host) -> None:
    repo_a = make_repo(alpha.path(""), UNIT)
    push(alpha)
    pull(beta)
    write(repo_a, "a.txt", "from alpha\n")
    push(alpha)
    write(beta.path(UNIT), "b.txt", "from beta\n")
    assert pull(beta, keep_local=True) == {UNIT: "skipped"}
    assert pull(beta) == {UNIT: "pulled"}
    aside = beta.relay_files(f"conflicts/beta/{UNIT}")
    assert len({p.split("/")[0] for p in aside}) == 1
    assert any(p.endswith("/b.txt") for p in aside)
    assert (beta.path(UNIT) / "a.txt").exists()
    assert (beta.path(UNIT) / "b.txt").exists()  # not deleted: never travelled
    assert states(beta) == {UNIT: "push pending"}


def test_adopt_identical_copy_without_baseline(alpha: Host, beta: Host) -> None:
    make_repo(alpha.path(""), UNIT)
    push(alpha)
    pull(beta)
    # beta loses its state (fresh install) but still has the identical copy
    beta.config.state_dir.rename(beta.tmp / "state.old")
    assert states(beta) == {UNIT: "unadopted"}
    assert push(beta) == {UNIT: "adopted"}
    assert states(beta) == {UNIT: "in sync"}


def test_bootstrap_copy_without_baseline(alpha: Host, beta: Host) -> None:
    repo_a = make_repo(alpha.path(""), UNIT)
    make_repo(beta.path(""), UNIT, {"README.md": "older copy\n"})  # hand-copied, stale
    push(alpha)
    assert states(beta) == {UNIT: "diverged"}
    assert push(beta) == {UNIT: "conflict"}
    assert pull(beta, dry_run=True) == {UNIT: "would pull"}
    assert beta.relay_files("conflicts") == []
    assert pull(beta, take_relay=True) == {UNIT: "pulled"}
    assert ls_files(beta.path(UNIT)) == ls_files(repo_a)
    assert states(beta) == {UNIT: "in sync"}


def test_modes_and_symlinks_round_trip(alpha: Host, beta: Host) -> None:
    repo = make_repo(alpha.path(""), UNIT, {"run.sh": "#!/bin/sh\n", "data.txt": "d\n"})
    (repo / "run.sh").chmod(0o755)
    (repo / "link").symlink_to("data.txt")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "exec+link")
    push(alpha)
    assert pull(beta) == {UNIT: "pulled"}
    copy = beta.path(UNIT)
    assert copy.joinpath("run.sh").stat().st_mode & 0o111 == 0o111
    assert str((copy / "link").readlink()) == "data.txt"
    assert git(copy, "status", "--porcelain") == ""
    assert states(beta) == {UNIT: "in sync"}

    (repo / "run.sh").chmod(0o644)
    (repo / "link").unlink()
    (repo / "link").symlink_to("run.sh")
    assert push(alpha) == {UNIT: "pushed"}
    assert pull(beta) == {UNIT: "pulled"}
    assert copy.joinpath("run.sh").stat().st_mode & 0o111 == 0
    assert str((copy / "link").readlink()) == "run.sh"
    assert git(copy, "status", "--porcelain") == git(repo, "status", "--porcelain")


def test_crypt_relay_hides_names(alpha: Host, relay: Relay) -> None:
    if relay.crypt is None:
        pytest.skip("plaintext relay")
    make_repo(alpha.path(""), UNIT, {"README.md": "secret project\n"})
    push(alpha)
    names = {p.name for p in Path(relay.path).rglob("*")}
    assert not names & {"work", "app", "README.md", "repos", "meta", ".git", "HEAD"}
    assert "secret project" not in b"".join(
        p.read_bytes() for p in Path(relay.path).rglob("*") if p.is_file()
    ).decode(errors="replace")
    assert alpha.relay_read(f"repos/{UNIT}/README.md") == "secret project\n"


def test_blocked_and_oversized_units_are_skipped(alpha: Host) -> None:
    locked = make_repo(alpha.path(""), "work/locked")
    (locked / ".git/index.lock").touch()
    make_repo(alpha.path(""), "work/big", {"blob.bin": "x" * 2 * 1024 * 1024})
    alpha.config.repos["work/big"] = RepoOverride(max_mb=1)
    assert push(alpha) == {"work/locked": "skipped", "work/big": "skipped"}
    assert states(alpha)["work/locked"] == "blocked"


def test_status_covers_relay_only_and_excluded_units(alpha: Host, beta: Host) -> None:
    make_repo(alpha.path(""), UNIT)
    make_repo(alpha.path(""), "work/excluded-thing")
    make_repo(alpha.path(""), "notincluded/repo")
    make_repo(alpha.path(""), "work/fresh")
    units = local_units(alpha.config)
    assert [u.id for u in units] == [UNIT, "work/fresh"]
    assert push(alpha, dry_run=True) == {UNIT: "would push", "work/fresh": "would push"}
    assert states(alpha) == {UNIT: "never pushed", "work/fresh": "never pushed"}
    push(alpha)
    assert states(beta) == {UNIT: "not local", "work/fresh": "not local"}
    assert pull(beta) == {UNIT: "pulled", "work/fresh": "pulled"}


def test_plain_directories_travel_too(alpha: Host, beta: Host) -> None:
    notes = alpha.path("work/notes")
    write(notes, "todo.md", "- things\n")
    write(notes, "deep/idea.txt", "x\n")
    write(notes, "node_modules/junk.js", "j\n")
    (notes / "run.sh").write_text("#!/bin/sh\n")
    (notes / "run.sh").chmod(0o755)
    units = local_units(alpha.config)
    assert [(u.id, u.kind) for u in units] == [("work/notes", "plain")]
    assert push(alpha) == {"work/notes": "pushed"}
    rows = alpha.engine().status(local_units(alpha.config))
    assert [(r.unit_id, r.kind, r.state) for r in rows] == [("work/notes", "plain", "in sync")]
    assert not any(p.startswith("node_modules/") for p in alpha.relay_files("repos/work/notes"))

    rows = beta.engine().status(local_units(beta.config))
    assert [(r.unit_id, r.kind, r.state) for r in rows] == [("work/notes", "plain", "not local")]
    assert pull(beta) == {"work/notes": "pulled"}
    copy = beta.path("work/notes")
    assert (copy / "todo.md").read_text() == "- things\n"
    assert (copy / "deep/idea.txt").exists()
    assert copy.joinpath("run.sh").stat().st_mode & 0o111 == 0o111
    assert not (copy / "node_modules").exists()
    assert states(beta) == {"work/notes": "in sync"}

    (notes / "deep/idea.txt").unlink()
    (notes / "deep").rmdir()  # empty directories travel too, so drop it for real
    write(notes, "todo.md", "- done\n")
    assert push(alpha) == {"work/notes": "pushed"}
    assert pull(beta) == {"work/notes": "pulled"}
    assert (copy / "todo.md").read_text() == "- done\n"
    assert not (copy / "deep").exists()


def test_unreadable_relay_is_not_treated_as_empty(
    alpha: Host, relay: Relay, tmp_path: Path
) -> None:
    from handoff.config import Crypt
    from handoff.errors import RelayError

    make_repo(alpha.path(""), UNIT)
    push(alpha)
    if relay.crypt is None:
        other = tmp_path / "other-pw"
        other.write_text("different\n")
        wrong = Relay(name="local", path=relay.path, backend=relay.backend, crypt=Crypt(other))
    else:
        wrong = Relay(name="local", path=relay.path, backend=relay.backend)  # plaintext view
    alpha.config.relays["local"] = wrong
    with pytest.raises(RelayError, match="not empty but holds nothing"):
        states(alpha)
