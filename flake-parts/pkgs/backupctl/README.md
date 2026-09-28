# backupctl

One entry point for the manual side of the restic backups: browsing,
restoring, replicating and maintaining the repositories on the Hetzner
Storage Box. Scheduled backups are not its job, those run through the
upstream NixOS `services.restic.backups`.

It knows nothing about Nix. Everything host-specific (repositories, password
files, SSH options, store paths of `restic`/`ssh`/`sftp`) comes from a JSON
config, rendered by the `tensorfiles.services.backup.restic` NixOS module to
`/etc/backupctl/config.json`. Another file can be passed with `--config` or
`BACKUPCTL_CONFIG`.

- `status [repo...] [--max-age HOURS]` -- newest snapshot and its age per copy
- `browse <repo> [--replica]` -- FUSE-mount all snapshots under `~/Backups`
- `replicate [repo...]` -- copy new snapshots into the local replicas
- `maintain [repo...]` -- `forget --prune` + `check` (needs full access)
- `sync-keys [--apply]` -- diff/upload the Storage Box `authorized_keys`
- `restic [--replica] <repo> [args...]` -- plain restic against a repository

Without `repo` arguments, `status`, `replicate` and `maintain` act on every
configured repository.

## Config

```json
{
  "restic": "/nix/store/…/bin/restic",
  "ssh": "/nix/store/…/bin/ssh",
  "sftp": "/nix/store/…/bin/sftp",
  "sshAlias": "restic-storagebox",
  "authorizedKeysFile": "/nix/store/…-storagebox-authorized-keys",
  "replicaRoot": "/mnt/hdd-backup/restic",
  "retention": ["--keep-daily=14"],
  "checkReadDataSubset": "5%",
  "browseDirectory": "Backups",
  "repositories": {
    "remotebundle": {
      "repository": "rclone:restic/remotebundle",
      "passwordFile": "/run/agenix/…",
      "options": { "rclone.program": "ssh -i … restic-storagebox" },
      "replica": "/mnt/hdd-backup/restic/remotebundle",
      "appendOnly": false
    }
  }
}
```

`authorizedKeysFile`, `replicaRoot` and every `replica` are optional (`null`
disables the matching commands).

## Development

```bash
nix build .#backupctl      # builds and runs the test suite
ruff check . && ruff format --check .
```
