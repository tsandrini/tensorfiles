"""Exceptions reported to the user as a one-line message instead of a traceback."""


class HandoffError(Exception):
    """Base class for expected failures."""


class ConfigError(HandoffError):
    """The config is missing, unreadable or malformed."""


class UsageError(HandoffError):
    """The command line asks for something the config cannot provide."""


class RelayError(HandoffError):
    """Talking to the relay failed."""
