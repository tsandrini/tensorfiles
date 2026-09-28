"""`backupctl sync-keys`: keep the Storage Box `authorized_keys` in sync with Nix."""

from __future__ import annotations

import argparse
import difflib
import subprocess
import sys
from pathlib import Path

from backupctl.config import Config
from backupctl.errors import BackupctlError, UsageError

REMOTE_PATH = ".ssh/authorized_keys"


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `sync-keys` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "sync-keys",
        help="diff (and upload) the Storage Box authorized_keys",
        description=(
            "Compare the Storage Box authorized_keys with the file rendered from Nix and, "
            "with --apply, upload it. Logs in with your own SSH key, not the service keys."
        ),
    )
    parser.add_argument("--apply", action="store_true", help="upload the rendered file")
    parser.set_defaults(func=run)


def diff(current: str, rendered: str) -> list[str]:
    """Unified diff from the Storage Box state to the rendered file.

    Args:
        current: Current `authorized_keys` on the Storage Box.
        rendered: File rendered from Nix.

    Returns:
        Diff lines, empty if both are equal.
    """
    return list(
        difflib.unified_diff(
            current.splitlines(keepends=True),
            rendered.splitlines(keepends=True),
            fromfile="storagebox",
            tofile="rendered",
        )
    )


def run(config: Config, args: argparse.Namespace) -> int:
    """Diff and optionally upload.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 if in sync (or uploaded), 1 if there is an unapplied difference.

    Raises:
        UsageError: `sync-keys` is not available on this host.
        BackupctlError: The current file cannot be read.
        subprocess.CalledProcessError: The upload or its verification failed.
    """
    if config.authorized_keys_file is None:
        raise UsageError("sync-keys is not available on this host (no authorizedKeysFile)")
    rendered_path = Path(config.authorized_keys_file)
    rendered = rendered_path.read_text()

    fetched = subprocess.run(
        [config.ssh, "-o", "BatchMode=yes", config.ssh_alias, "cat", REMOTE_PATH],
        text=True,
        capture_output=True,
        check=False,
    )
    if fetched.returncode != 0:
        raise BackupctlError(f"cannot read the current {REMOTE_PATH}: {fetched.stderr.strip()}")

    changes = diff(fetched.stdout, rendered)
    if not changes:
        print("storage box authorized_keys are up to date")
        return 0

    sys.stdout.writelines(changes)
    if not args.apply:
        print("\nre-run with --apply to upload the rendered file")
        return 1

    # NOTE: SFTPv3 `rename` does not overwrite, hence rm + rename
    batch = (
        f"put {rendered_path} {REMOTE_PATH}.tmp\n"
        f"rm {REMOTE_PATH}\n"
        f"rename {REMOTE_PATH}.tmp {REMOTE_PATH}\n"
    )
    subprocess.run([config.sftp, "-b", "-", config.ssh_alias], input=batch, text=True, check=True)
    print("uploaded, verifying the login")
    subprocess.run([config.ssh, "-o", "BatchMode=yes", config.ssh_alias, "pwd"], check=True)
    return 0
