"""Exceptions reported to the user as a one-line message instead of a traceback."""


class BackupctlError(Exception):
    """Base class for expected failures."""


class ConfigError(BackupctlError):
    """The config is missing, unreadable or malformed."""


class UsageError(BackupctlError):
    """The command line asks for something the config cannot provide."""
