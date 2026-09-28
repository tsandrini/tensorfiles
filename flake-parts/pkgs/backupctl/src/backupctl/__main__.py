"""Allows `python -m backupctl`."""

import sys

from backupctl.cli import main

sys.exit(main())
