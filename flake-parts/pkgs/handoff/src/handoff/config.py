"""Loading and validation of the handoff TOML config."""

from __future__ import annotations

import os
import socket
import tomllib
from dataclasses import dataclass, field
from fnmatch import fnmatchcase
from pathlib import Path
from typing import Any

from handoff.errors import ConfigError, UsageError

CONFIG_ENV = "HANDOFF_CONFIG"

DEFAULT_ALWAYS_EXCLUDE = (
    "node_modules",
    ".direnv",
    ".devenv",
    "target",
    "result",
    "result-*",
)


def default_config_path() -> Path:
    """`$XDG_CONFIG_HOME/handoff/config.toml`, falling back to `~/.config`.

    Returns:
        Path of the default config file.
    """
    base = os.environ.get("XDG_CONFIG_HOME") or "~/.config"
    return Path(base).expanduser() / "handoff" / "config.toml"


def default_state_dir() -> Path:
    """`$XDG_STATE_HOME/handoff`, falling back to `~/.local/state`.

    Returns:
        Directory holding the per-host sync state.
    """
    base = os.environ.get("XDG_STATE_HOME") or "~/.local/state"
    return Path(base).expanduser() / "handoff"


@dataclass(frozen=True)
class Crypt:
    """Client-side encryption of the relay (rclone `crypt`).

    Attributes:
        password_file: File holding the crypt password (one line).
        salt_file: File holding the optional salt, `None` for none.
    """

    password_file: Path
    salt_file: Path | None = None


@dataclass(frozen=True)
class Relay:
    """Where the canonical copies live: an rclone backend plus a path on it.

    Attributes:
        name: Config key of the relay.
        path: Absolute directory on the backend holding `repos/`, `meta/`, ...
        backend: rclone backend parameters (`type` plus whatever the backend
            needs, e.g. `host`, `user`, `port`, `key_file` for sftp); every
            value is handed to rclone verbatim.
        crypt: Encryption settings, `None` for a plaintext relay.
        history: Keep overwritten and removed files under `history/` on push.
        transfers: Parallel rclone transfers.
    """

    name: str
    path: str
    backend: dict[str, str]
    crypt: Crypt | None = None
    history: bool = True
    transfers: int = 16


@dataclass(frozen=True)
class Rules:
    """What travels for one unit.

    Attributes:
        always_exclude: Names (or `/`-containing relative paths) that never
            travel, even if not gitignored -- build output and dependency trees.
        keep_ignored: Globs, relative to the repository, of gitignored files
            that travel anyway (`.env`, local configs).
        max_mb: Skip the unit with a warning when its file set is larger,
            `None` for no limit.
    """

    always_exclude: tuple[str, ...] = DEFAULT_ALWAYS_EXCLUDE
    keep_ignored: tuple[str, ...] = ()
    max_mb: float | None = 2000.0

    def merged(self, override: RepoOverride) -> Rules:
        """Apply a per-repository override.

        Args:
            override: Additions and replacements for this repository.

        Returns:
            The effective rules.
        """
        return Rules(
            always_exclude=self.always_exclude + override.always_exclude,
            keep_ignored=self.keep_ignored + override.keep_ignored,
            max_mb=self.max_mb if override.max_mb is None else override.max_mb,
        )


@dataclass(frozen=True)
class RepoOverride:
    """Per-repository additions to the default rules.

    Attributes:
        always_exclude: Extra excludes for this repository.
        keep_ignored: Extra ignored globs that still travel.
        max_mb: Size limit replacing the default, `0` disables the limit.
    """

    always_exclude: tuple[str, ...] = ()
    keep_ignored: tuple[str, ...] = ()
    max_mb: float | None = None


@dataclass(frozen=True)
class Workspace:
    """Where the repositories are discovered.

    Attributes:
        root: Directory scanned for repositories.
        depth: Repositories are expected exactly this many levels below `root`
            (`2` means `<root>/<bundle>/<repo>`).
        include: fnmatch globs on the unit id (`<bundle>/<repo>`); when
            non-empty, only matching units are handled.
        exclude: fnmatch globs on the unit id that are never touched, in
            either direction; wins over `include`.
    """

    root: Path
    depth: int = 2
    include: tuple[str, ...] = ()
    exclude: tuple[str, ...] = ()

    def selects(self, unit_id: str) -> bool:
        """Whether a unit id is handled at all.

        Args:
            unit_id: `<bundle>/<repo>`.

        Returns:
            `True` when included (or no include list) and not excluded.
        """
        if any(fnmatchcase(unit_id, p) for p in self.exclude):
            return False
        return not self.include or any(fnmatchcase(unit_id, p) for p in self.include)


DEFAULT_CLAUDE_INCLUDE = (
    "projects/*",
    "file-history/*",
    "history.jsonl",
    "plans/*",
    "tasks/*",
    "paste-cache/*",
)


@dataclass(frozen=True)
class ClaudeState:
    """Claude Code runtime state carried as a merge unit (see `handoff.merge`).

    Attributes:
        root: The `~/.claude` directory.
        include: fnmatch globs (relative to `root`) of what travels. The
            default covers sessions, rewind checkpoints, prompt history,
            plans, task output and pasted content; everything else in the
            directory is machine-local or managed by home-manager.
        exclude: Globs that never travel, applied after `include`.
        conflicts_dir: Directory below `root` receiving the other host's
            version of a diverged file; never travels itself.
    """

    root: Path
    include: tuple[str, ...] = DEFAULT_CLAUDE_INCLUDE
    exclude: tuple[str, ...] = ()
    conflicts_dir: str = "handoff-conflicts"

    def selects(self, rel_path: str) -> bool:
        """Whether a file below `root` travels.

        Args:
            rel_path: `/`-separated path relative to `root`.

        Returns:
            `True` when included and not excluded.
        """
        if rel_path == self.conflicts_dir or rel_path.startswith(self.conflicts_dir + "/"):
            return False
        if any(fnmatchcase(rel_path, p) for p in self.exclude):
            return False
        return any(fnmatchcase(rel_path, p) for p in self.include)


@dataclass(frozen=True)
class Config:
    """Parsed handoff config.

    Attributes:
        relays: Configured relays keyed by name.
        default_relay: Relay used without `--relay`.
        workspace: Repository discovery settings.
        defaults: Rules applied to every repository.
        repos: Per-repository overrides keyed by unit id.
        claude: Claude Code state settings, `None` when not synced.
        host: Name this machine signs its pushes with.
        state_dir: Directory holding the per-host sync state.
    """

    relays: dict[str, Relay]
    default_relay: str
    workspace: Workspace
    defaults: Rules = field(default_factory=Rules)
    repos: dict[str, RepoOverride] = field(default_factory=dict)
    claude: ClaudeState | None = None
    host: str = field(default_factory=socket.gethostname)
    state_dir: Path = field(default_factory=default_state_dir)

    def relay(self, name: str | None) -> Relay:
        """Pick a relay.

        Args:
            name: `--relay` value, the default relay when `None`.

        Returns:
            The relay.

        Raises:
            UsageError: The name is not configured.
        """
        name = name or self.default_relay
        if name not in self.relays:
            known = ", ".join(self.relays) or "none"
            raise UsageError(f"unknown relay {name!r} (configured: {known})")
        return self.relays[name]

    def rules_for(self, unit_id: str) -> Rules:
        """Effective rules of one unit.

        Args:
            unit_id: `<bundle>/<repo>`.

        Returns:
            Defaults merged with the unit's override, if any.
        """
        override = self.repos.get(unit_id)
        return self.defaults if override is None else self.defaults.merged(override)


def resolve_path(cli_path: str | None) -> Path:
    """Pick the config file: `--config`, then `$HANDOFF_CONFIG`, then the default.

    Args:
        cli_path: Value of `--config`, if given.

    Returns:
        Path of the config file to load.
    """
    if cli_path:
        return Path(cli_path)
    if env_path := os.environ.get(CONFIG_ENV):
        return Path(env_path)
    return default_config_path()


def load(path: Path) -> Config:
    """Read and parse a config file.

    Args:
        path: TOML config file.

    Returns:
        The parsed config.

    Raises:
        ConfigError: The file cannot be read or is not valid.
    """
    try:
        data = tomllib.loads(path.read_text())
    except OSError as err:
        raise ConfigError(f"cannot read {path}: {err.strerror}") from err
    except tomllib.TOMLDecodeError as err:
        raise ConfigError(f"{path} is not valid TOML: {err}") from err
    return parse(data)


def _path(value: str) -> Path:
    """Expand `$VAR`, `${VAR}` and `~` in a configured path.

    Args:
        value: Raw string from the config.

    Returns:
        The expanded path.
    """
    return Path(os.path.expandvars(value)).expanduser()


def _table(data: dict[str, Any], key: str, where: str, *, required: bool = True) -> dict:
    value = data.get(key)
    if value is None:
        if required:
            raise ConfigError(f"missing `[{key}]` in {where}")
        return {}
    if not isinstance(value, dict):
        raise ConfigError(f"`{key}` in {where} has to be a table")
    return value


def _strings(data: dict[str, Any], key: str, where: str) -> tuple[str, ...]:
    value = data.get(key, [])
    if not isinstance(value, list) or not all(isinstance(v, str) for v in value):
        raise ConfigError(f"`{key}` in {where} has to be a list of strings")
    return tuple(value)


def _number(data: dict[str, Any], key: str, where: str) -> float | None:
    value = data.get(key)
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, int | float):
        raise ConfigError(f"`{key}` in {where} has to be a number")
    return float(value)


def _parse_relay(name: str, raw: dict[str, Any]) -> Relay:
    where = f"[relay.{name}]"
    path = raw.get("path")
    if not isinstance(path, str) or not path.startswith("/"):
        raise ConfigError(f"`path` in {where} has to be an absolute path")
    backend = _table(raw, "backend", where)
    if not isinstance(backend.get("type"), str):
        raise ConfigError(f'`backend.type` in {where} is required (e.g. "sftp", "local")')
    rendered = {}
    for key, value in backend.items():
        if isinstance(value, bool):
            rendered[key] = "true" if value else "false"
        elif isinstance(value, str):
            rendered[key] = os.path.expandvars(value)
        elif isinstance(value, int | float):
            rendered[key] = str(value)
        else:
            raise ConfigError(f"`backend.{key}` in {where} has to be a string, number or bool")
    crypt = None
    if "crypt" in raw:
        raw_crypt = _table(raw, "crypt", where)
        password_file = raw_crypt.get("password_file")
        if not isinstance(password_file, str) or not password_file:
            raise ConfigError(f"`crypt.password_file` in {where} is required")
        salt_file = raw_crypt.get("salt_file")
        crypt = Crypt(
            password_file=_path(password_file),
            salt_file=_path(salt_file) if salt_file else None,
        )
    transfers = raw.get("transfers", 16)
    if isinstance(transfers, bool) or not isinstance(transfers, int) or transfers < 1:
        raise ConfigError(f"`transfers` in {where} has to be a positive integer")
    return Relay(
        name=name,
        path=path.rstrip("/") or "/",
        backend=rendered,
        crypt=crypt,
        history=bool(raw.get("history", True)),
        transfers=transfers,
    )


def parse(data: Any) -> Config:
    """Build a `Config` from decoded TOML.

    Args:
        data: Decoded TOML document.

    Returns:
        The parsed config.

    Raises:
        ConfigError: A required key is missing or has the wrong shape.
    """
    if not isinstance(data, dict):
        raise ConfigError("the config has to be a TOML document")

    raw_relay = _table(data, "relay", "the config")
    relays = {
        name: _parse_relay(name, raw) for name, raw in raw_relay.items() if isinstance(raw, dict)
    }
    if not relays:
        raise ConfigError("no relays configured (add a `[relay.<name>]` table)")
    default_relay = raw_relay.get("default") or next(iter(relays))
    if default_relay not in relays:
        raise ConfigError(f"`relay.default` names an unknown relay {default_relay!r}")

    raw_ws = _table(data, "workspace", "the config")
    root = raw_ws.get("root")
    if not isinstance(root, str) or not root:
        raise ConfigError("missing `root` in [workspace]")
    depth = raw_ws.get("depth", 2)
    if isinstance(depth, bool) or not isinstance(depth, int) or depth < 1:
        raise ConfigError("`depth` in [workspace] has to be a positive integer")
    workspace = Workspace(
        root=_path(root),
        depth=depth,
        include=_strings(raw_ws, "include", "[workspace]"),
        exclude=_strings(raw_ws, "exclude", "[workspace]"),
    )

    raw_defaults = _table(data, "defaults", "the config", required=False)
    defaults = Rules(
        always_exclude=(
            _strings(raw_defaults, "always_exclude", "[defaults]")
            if "always_exclude" in raw_defaults
            else DEFAULT_ALWAYS_EXCLUDE
        ),
        keep_ignored=_strings(raw_defaults, "keep_ignored", "[defaults]"),
        max_mb=(
            _number(raw_defaults, "max_mb", "[defaults]")
            if "max_mb" in raw_defaults
            else Rules.max_mb
        ),
    )

    repos = {}
    for unit_id, raw in _table(data, "repo", "the config", required=False).items():
        where = f'[repo."{unit_id}"]'
        if not isinstance(raw, dict):
            raise ConfigError(f"{where} has to be a table")
        repos[unit_id] = RepoOverride(
            always_exclude=_strings(raw, "always_exclude", where),
            keep_ignored=_strings(raw, "keep_ignored", where),
            max_mb=_number(raw, "max_mb", where),
        )

    claude = None
    if "claude" in data:
        raw_claude = _table(data, "claude", "the config")
        if raw_claude.get("enable", True):
            claude = ClaudeState(
                root=_path(str(raw_claude.get("root", "~/.claude"))),
                include=(
                    _strings(raw_claude, "include", "[claude]")
                    if "include" in raw_claude
                    else DEFAULT_CLAUDE_INCLUDE
                ),
                exclude=_strings(raw_claude, "exclude", "[claude]"),
                conflicts_dir=str(raw_claude.get("conflicts_dir", "handoff-conflicts")).strip("/"),
            )

    extra: dict[str, Any] = {}
    if host := data.get("host"):
        extra["host"] = str(host)
    if state_dir := data.get("state_dir"):
        extra["state_dir"] = _path(str(state_dir))

    return Config(
        relays=relays,
        default_relay=default_relay,
        workspace=workspace,
        defaults=defaults,
        repos=repos,
        claude=claude,
        **extra,
    )
