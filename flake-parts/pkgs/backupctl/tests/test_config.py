"""Config parsing, loading and repository selection."""

from __future__ import annotations

from pathlib import Path

import pytest

from backupctl.config import DEFAULT_CONFIG_PATH, Config, load, parse, resolve_path
from backupctl.errors import ConfigError, UsageError


def test_parse_sample(config: Config) -> None:
    assert config.ssh_alias == "restic-storagebox"
    assert list(config.repositories) == ["alpha", "beta"]
    alpha = config.repositories["alpha"]
    assert alpha.replica == "/replicas/alpha"
    assert alpha.options == {"rclone.program": "ssh -i key restic-storagebox"}
    assert not alpha.append_only
    beta = config.repositories["beta"]
    assert beta.append_only
    assert beta.replica is None
    assert beta.options == {}


def test_parse_optional_defaults(sample: dict) -> None:
    for key in ("replicaRoot", "retention", "checkReadDataSubset", "authorizedKeysFile"):
        del sample[key]
    config = parse(sample)
    assert config.replica_root is None
    assert config.retention == []
    assert config.check_read_data_subset == "5%"
    assert config.authorized_keys_file is None


@pytest.mark.parametrize("key", ["restic", "ssh", "sftp", "sshAlias", "repositories"])
def test_parse_missing_top_level_key(sample: dict, key: str) -> None:
    del sample[key]
    with pytest.raises(ConfigError, match=f"`{key}`"):
        parse(sample)


def test_parse_missing_repository_key(sample: dict) -> None:
    del sample["repositories"]["alpha"]["passwordFile"]
    with pytest.raises(ConfigError, match=r"passwordFile.*repositories\.alpha"):
        parse(sample)


def test_parse_rejects_non_object() -> None:
    with pytest.raises(ConfigError):
        parse([])


def test_load_reports_invalid_json(tmp_path: Path) -> None:
    path = tmp_path / "config.json"
    path.write_text("{ nope")
    with pytest.raises(ConfigError, match="not valid JSON"):
        load(path)


def test_load_reports_missing_file(tmp_path: Path) -> None:
    with pytest.raises(ConfigError, match="cannot read"):
        load(tmp_path / "missing.json")


def test_resolve_path_precedence(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("BACKUPCTL_CONFIG", raising=False)
    assert resolve_path(None) == DEFAULT_CONFIG_PATH
    monkeypatch.setenv("BACKUPCTL_CONFIG", "/from/env.json")
    assert resolve_path(None) == Path("/from/env.json")
    assert resolve_path("/from/cli.json") == Path("/from/cli.json")


def test_select_defaults_to_all(config: Config) -> None:
    assert [repo.name for repo in config.select([])] == ["alpha", "beta"]


def test_select_keeps_requested_order(config: Config) -> None:
    assert [repo.name for repo in config.select(["beta", "alpha"])] == ["beta", "alpha"]


def test_select_unknown(config: Config) -> None:
    with pytest.raises(UsageError, match="unknown repository 'gamma'"):
        config.select(["gamma"])


def test_select_require_replica(config: Config) -> None:
    assert [repo.name for repo in config.select([], require_replica=True)] == ["alpha"]
    with pytest.raises(UsageError, match="no replica"):
        config.select(["beta"], require_replica=True)
