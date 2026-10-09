"""Claude state as a merge unit: per-file reconciliation through the relay."""

from __future__ import annotations

import json
import os
import uuid
from pathlib import Path

import pytest

from handoff.merge import MergeEngine, merge_history

from .conftest import Host, make_repo, write

S1, S2, S3 = (str(uuid.uuid4()) for _ in range(3))
SLUG = "projects/-home-me-work"


def engine(host: Host) -> MergeEngine:
    base = host.engine()
    assert host.config.claude is not None
    return MergeEngine(host.config, host.config.claude, base.store, base.state)


def root(host: Host) -> Path:
    assert host.config.claude is not None
    return host.config.claude.root


def hist_line(ts: int, text: str) -> str:
    return json.dumps({"display": text, "timestamp": ts, "project": "/x", "sessionId": S1}) + "\n"


def register(host: Host, session: str, pid: int) -> None:
    write(
        root(host),
        f"sessions/{pid}.json",
        json.dumps({"sessionId": session, "pid": pid, "cwd": "/x", "status": "running"}),
    )


def seed(host: Host) -> None:
    r = root(host)
    write(r, f"{SLUG}/{S1}.jsonl", '{"turn":1}\n')
    write(r, f"{SLUG}/{S1}/tool-results/out.txt", "result\n")
    write(r, f"file-history/{S1}/abc@v1", "old content\n")
    write(r, "history.jsonl", hist_line(100, "first"))
    write(r, "plans/plan.md", "# plan\n")
    write(r, "paste-cache/p1.txt", "pasted\n")
    write(r, "tasks/t1/output.txt", "task\n")
    write(r, "sessions/1.json", "{}")
    write(r, "debug/d.log", "noise\n")
    write(r, "settings.json", "{}")
    write(r, "shell-snapshots/snap.sh", "export X=1\n")


# --- helpers ---


def test_merge_history_is_a_sorted_union() -> None:
    a = hist_line(2, "b") + hist_line(1, "a")
    b = hist_line(2, "b") + hist_line(3, "c")
    merged = merge_history([a, b])
    assert [json.loads(line)["display"] for line in merged.splitlines()] == ["a", "b", "c"]


# --- round trips ---


def test_push_pull_round_trip_includes_only_state(alpha: Host, beta: Host) -> None:
    seed(alpha)
    (root(alpha) / "plans/plan.md").chmod(0o600)
    out = engine(alpha).push()
    assert not out.failed and not out.conflicts
    on_relay = set(alpha.relay_files("state/claude"))
    assert f"{SLUG}/{S1}.jsonl" in on_relay
    assert f"{SLUG}/{S1}/tool-results/out.txt" in on_relay
    assert "history.jsonl" in on_relay and "paste-cache/p1.txt" in on_relay
    assert not any(p.startswith(("sessions/", "debug/", "shell-snapshots/")) for p in on_relay)
    assert "settings.json" not in on_relay
    assert engine(alpha).push().uploaded == []  # nothing new

    out = engine(beta).pull()
    assert not out.failed and not out.conflicts
    assert sorted(out.downloaded) == sorted(on_relay)
    r = root(beta)
    assert (r / f"{SLUG}/{S1}.jsonl").read_text() == '{"turn":1}\n'
    assert (r / "plans/plan.md").stat().st_mode & 0o777 == 0o600
    assert (r / "plans/plan.md").stat().st_mtime_ns == (
        root(alpha) / "plans/plan.md"
    ).stat().st_mtime_ns
    assert not (r / "debug").exists()
    st = engine(beta).status()
    assert (st.to_push, st.to_pull, st.diverged) == (0, 0, 0)
    assert engine(beta).pull().downloaded == []


def test_appends_flow_both_ways_and_divergence_is_kept_aside(alpha: Host, beta: Host) -> None:
    seed(alpha)
    engine(alpha).push()
    engine(beta).pull()
    session = f"{SLUG}/{S1}.jsonl"

    with (root(alpha) / session).open("a") as f:
        f.write('{"turn":2}\n')
    assert engine(alpha).push().uploaded == [session]
    assert engine(beta).pull().downloaded == [session]
    assert (root(beta) / session).read_text() == '{"turn":1}\n{"turn":2}\n'

    with (root(beta) / session).open("a") as f:
        f.write('{"turn":3}\n')
    assert engine(beta).push().uploaded == [session]
    assert engine(alpha).pull().downloaded == [session]
    assert (root(alpha) / session).read_text().count("\n") == 3

    # both extend the same session: alpha wins the relay, beta's copy is set aside
    with (root(alpha) / session).open("a") as f:
        f.write('{"turn":"4a"}\n')
    with (root(beta) / session).open("a") as f:
        f.write('{"turn":"4b"}\n')
    assert engine(alpha).push().uploaded == [session]
    out = engine(beta).push()
    assert out.conflicts == [session] and out.uploaded == []
    assert any(p.endswith(session) for p in beta.relay_files("conflicts/beta/claude"))
    out = engine(beta).pull()
    assert out.conflicts == [session] and out.downloaded == []
    assert '"4b"' in (root(beta) / session).read_text()  # local kept
    aside = root(beta) / "handoff-conflicts" / "alpha" / session
    assert '"4a"' in aside.read_text()
    assert engine(beta).status().diverged == 1
    assert engine(beta).push().uploaded == []  # conflicts dir never travels


def test_history_merges_as_union(alpha: Host, beta: Host) -> None:
    seed(alpha)
    engine(alpha).push()
    engine(beta).pull()
    with (root(alpha) / "history.jsonl").open("a") as f:
        f.write(hist_line(200, "from alpha"))
    with (root(beta) / "history.jsonl").open("a") as f:
        f.write(hist_line(150, "from beta"))
    assert engine(alpha).push().uploaded == ["history.jsonl"]
    out = engine(beta).push()
    assert out.merged_history and out.uploaded == ["history.jsonl"] and not out.conflicts
    texts = [
        json.loads(ln)["display"] for ln in (root(beta) / "history.jsonl").read_text().splitlines()
    ]
    assert texts == ["first", "from beta", "from alpha"]
    out = engine(alpha).pull()
    assert out.merged_history and out.downloaded == ["history.jsonl"]
    assert (root(alpha) / "history.jsonl").read_text() == (root(beta) / "history.jsonl").read_text()


def test_live_sessions_are_reported_and_never_overwritten(alpha: Host, beta: Host) -> None:
    seed(alpha)
    register(alpha, S1, os.getpid())
    register(alpha, S2, 999_999_999)  # dead pid: not live
    out = engine(alpha).push()
    assert f"{SLUG}/{S1}.jsonl" in out.uploaded
    st = engine(beta).status()
    assert st.live_elsewhere == [S1]

    engine(beta).pull()
    register(beta, S1, os.getpid())
    with (root(alpha) / f"{SLUG}/{S1}.jsonl").open("a") as f:
        f.write('{"turn":2}\n')
    engine(alpha).push()
    out = engine(beta).pull()
    assert out.skipped_live == [f"{SLUG}/{S1}.jsonl"] and out.downloaded == []
    assert (root(beta) / f"{SLUG}/{S1}.jsonl").read_text() == '{"turn":1}\n'


def test_pull_takes_recent_pushes_only_unless_all(alpha: Host, beta: Host) -> None:
    seed(alpha)
    engine(alpha).push()
    engine(beta).pull()
    (root(beta) / f"{SLUG}/{S1}.jsonl").unlink()  # beta cleaned it up
    write(root(alpha), f"{SLUG}/{S2}.jsonl", '{"turn":1}\n')
    engine(alpha).push()
    out = engine(beta).pull()
    assert out.downloaded == [f"{SLUG}/{S2}.jsonl"]
    assert not (root(beta) / f"{SLUG}/{S1}.jsonl").exists()
    out = engine(beta).pull(everything=True)
    assert out.downloaded == [f"{SLUG}/{S1}.jsonl"]
    assert (root(beta) / f"{SLUG}/{S1}.jsonl").exists()


def test_dry_run_changes_nothing(alpha: Host, beta: Host) -> None:
    seed(alpha)
    out = engine(alpha).push(dry_run=True)
    assert len(out.uploaded) == 7 and alpha.relay_files("state/claude") == []
    engine(alpha).push()
    out = engine(beta).pull(dry_run=True)
    assert len(out.downloaded) == 7 and not root(beta).exists()


@pytest.mark.parametrize("args", [["claude"], ["work/", "claude"]])
def test_cli_selects_claude(alpha: Host, args: list[str], capsys: pytest.CaptureFixture) -> None:
    from handoff import cli
    from handoff.commands import push

    seed(alpha)
    make_repo(alpha.path(""), "work/app")
    ns = cli.build_parser().parse_args(["push", "--relay", "local", *args])
    assert push.run(alpha.config, ns) == 0
    out = capsys.readouterr().out
    assert "claude  pushed: 7 files" in out
    assert ("summary:" in out) == ("work/" in args)
