# handoff

Carry dirty git working trees between machines without committing: `handoff
push` before you leave, `handoff pull` when you arrive. Everything a
repository holds that is not gitignored travels, plus the whole `.git`
(index, stashes, reflogs, branches, remotes, in-progress rebases), plus an
explicit list of gitignored files that should travel anyway (`.env`).
Directories without git at the same depth (notes, scratch folders) travel
wholesale. Build output and dependency trees never travel. The relay is
encrypted client-side, so a rented Storage Box only ever sees ciphertext and
ciphertext names.

It is a plain copier with a precise file set and a safety protocol, not a
merge tool. One host works on a repository at a time; the protocol makes sure
the other host cannot silently lose work when that assumption breaks.

- `status [unit...] [--json]` -- `in sync`, `push pending`, `pull pending`,
  `conflict`, ... per repository
- `push [unit...] [--force] [-n]` -- copy changed local repositories to the
  relay
- `pull [unit...] [--take-relay | --keep-local] [-n]` -- bring the relay's
  copies into the workspace
- `verify [unit...] [--fix] [--rehash] [-n]` -- hash local files and compare
  them with the relay's recorded hashes

A `unit` is `<bundle>/<repo>` relative to the workspace root; `bundle/`
selects a whole bundle. Without arguments every unit is acted on.

## Relay

The relay is any rclone backend plus a path on it: the Hetzner Storage Box
over sftp, a USB disk, a directory on another host. With `crypt` configured,
rclone's crypt layer encrypts file contents and every path segment
client-side; the password lives in a file (an agenix secret in tensorfiles).
Layout below the relay path:

```text
repos/<unit>/<path>                 canonical copy (regular files only)
meta/index.json                     generation, host, time, fingerprint per unit
meta/<unit>.files                   everything the copy holds: dirs, links,
                                    sizes, nanosecond mtimes, modes
history/<time>/<unit>/<path>        files a push overwrote or removed
conflicts/<host>/<unit>/<time>/     local copies a pull set aside
state/claude/<path>                 Claude Code state (merge unit)
merge-meta/claude.{json,files}      its stamp and per-file list
```

rclone is configured purely through environment variables, so no rclone
config file is written and the password never appears on a command line.

## Protocol

Each host remembers, per unit, the generation it last synced with and the
fingerprint its copy is expected to have (the baseline, under
`$XDG_STATE_HOME/handoff`). The fingerprint covers paths, kinds, sizes,
nanosecond mtimes, modes and link targets of everything that travels, with
the git index tracked by content (`git ls-files -s`), so a `git status` that
merely refreshes stat data does not count as a change while a `git add` does.

Transfers never rely on remote timestamps (sftp keeps whole seconds). The
pusher diffs its file set against the relay's recorded one and uploads
exactly the differing files; the puller diffs the relay's set against its own
disk, downloads what differs, then restores directories, symlinks, modes and
mtimes itself. All units of one command move in a single rclone batch, with rclone's
live progress (files, bytes, rate, ETA) on the terminal and a stats line
every 30 s when output is not a terminal. Scanning the workspace runs in
forked worker processes; with a few hundred repositories `status` takes a
few seconds, most of it one relay round trip per metadata file.

- **push** refuses a unit whose relay copy moved on since the baseline
  (`pull first, or push --force`). `--force` overwrites; what the relay had
  and this host lacks goes to `history/`.
- **pull** of a unit with local changes since the baseline first copies the
  local file set to `conflicts/<host>/...` on the relay, then takes the relay
  copy. `--keep-local` skips such units instead; `--take-relay` overwrites
  without setting anything aside and makes the local copy an exact mirror of
  the tracked set.
- A host with no baseline but a copy identical to the relay adopts it
  silently; a differing copy counts as a conflict until `pull --take-relay`
  or `push --force` decides.
- Deletions propagate through the recorded file sets: a pull removes what the
  previous sync brought and the relay no longer has (files and links only;
  directories are dropped once empty, so gitignored artefacts inside them
  survive).
- Units with `index.lock`, a merge, rebase or cherry-pick in progress are
  skipped in both directions. Symlinks are never uploaded; their targets
  travel in the file set and are recreated on pull.
- A relay path that holds files this config cannot read (another crypt
  password, or crypt against a plaintext tree) is an error, never "empty",
  so a push cannot start a second, unrelated tree next to the real one.

## Claude Code state

`~/.claude` is a different animal: both machines write to it, so there is no
canonical copy to protect. With a `[claude]` table the runtime state that
home-manager does not manage travels as a _merge unit_, reconciled per file:

- what travels: sessions (`projects/`), rewind checkpoints (`file-history/`),
  the prompt history, plans, task output and pasted content; the live
  registry, shell snapshots, caches, credentials, debug and telemetry stay
  home, and so does everything the home-manager module renders;
- a session file only ever grows, so the shorter copy being a byte prefix of
  the longer one is the normal case: push uploads new and extended files,
  pull downloads them, verified byte for byte after the download;
- a file that diverged on both sides is never overwritten: push parks the
  local version under `conflicts/` on the relay, pull parks the relay's
  version under `~/.claude/handoff-conflicts/<host>/...`, and `status`
  counts it as diverged;
- the prompt history is merged as a union of lines ordered by timestamp;
- deletions never propagate and a pull only considers what other hosts
  pushed since this host's last pull (`pull --all` reconciles everything,
  for a fresh machine or to get an old session back);
- a session the local registry reports as running is never overwritten by a
  pull, and `status` on the other machine lists it under "live elsewhere"
  so you do not resume it there.

`handoff push claude` / `pull claude` act on the state alone; without
arguments every command covers repositories and the state.

```toml
[claude]
root = "~/.claude"                   # default
# include = [...]                    # default: the list above
exclude = []
conflicts_dir = "handoff-conflicts"
```

## Config

TOML, at `--config`, then `$HANDOFF_CONFIG`, then
`$XDG_CONFIG_HOME/handoff/config.toml`. It names repositories, so keep it
private.

```toml
host = "flatbundle"                  # default: the hostname

[relay]
default = "storagebox"

[relay.storagebox]
path = "/home/handoff"               # absolute, on the backend
history = true
transfers = 16

[relay.storagebox.backend]           # handed to rclone verbatim
type = "sftp"
host = "uXXXXXX.your-storagebox.de"
user = "uXXXXXX"
port = 23
key_file = "~/.ssh/id_ed25519"
known_hosts_file = "~/.ssh/known_hosts"

[relay.storagebox.crypt]
password_file = "$XDG_RUNTIME_DIR/agenix/common/handoff-crypt-password"

[relay.usb]
path = "/mnt/usb/handoff"
backend = { type = "local" }         # plaintext local directory

[workspace]
root = "~/ProjectBundle"
depth = 2                            # <root>/<bundle>/<repo>
include = ["meteopress/*", "tsandrini/*"]
exclude = ["tsandrini/nixpkgs", "*_bkp"]

[defaults]
always_exclude = ["node_modules", ".direnv", ".devenv", "target", "result", "result-*"]
keep_ignored = [".env", ".env.*", ".envrc.local"]
max_mb = 2000                        # skip bigger units with a warning

[repo."meteopress/radar-kit-fu"]
keep_ignored = ["config/local.yaml"]
always_exclude = ["data"]
max_mb = 0                           # no limit for this one
```

`backend` is handed to rclone verbatim (`type` plus whatever that backend
needs), `crypt.salt_file` is optional. Paths expand `~` and environment
variables, so one config file serves hosts with different UIDs.
`always_exclude` entries without `/` match a path segment anywhere
(`node_modules` at any depth); entries with `/` match the whole path
relative to the repository. `keep_ignored` are globs
relative to the repository. Units are discovered, not listed;
`include`/`exclude` are fnmatch globs on the unit id. A directory at
repository depth is a git unit when it has a `.git` and a plain unit
otherwise (`status` shows the kind); `always_exclude` and `max_mb` apply to
both.

Changing the crypt password orphans everything on the relay: wipe the relay
path and push again from the host that holds the current state.

## Verifying contents

Sync decisions are stat-based (size, nanosecond mtime, mode). A file whose
content changed while its stat data did not is invisible to push, pull and
status. That is rare in normal use but easy to manufacture: `rsync
--size-only` skips same-size files yet still copies their mtime, and every
git ref is 41 bytes. `verify` closes the gap: push records a SHA-256 for
every uploaded file, and `verify` hashes the local files of each in-sync
unit and reports the ones that differ from the relay. `--fix` restores them
from the relay; `--rehash` publishes the local hashes for units the relay
has no hashes for yet, and belongs on the host whose copies are known to be
good. Hashing the whole workspace takes about a minute per 10 GiB.

## Bootstrapping a second machine

Copying the workspace by hand first saves the initial transfer, but the copy
has no baseline. After `push` on the original host, run
`pull --take-relay` on the copy: identical units are adopted, differing ones
become exact mirrors. A `tar` copy truncates mtimes to seconds, which makes
every file look changed; the pull then re-downloads the tracked set. A plain
`rsync -a` pass over the LAN first (never `--size-only`) brings the copy to
the same bytes and timestamps, and `verify` afterwards proves it.

## Limits

- sftp costs several round trips per file, so the first push of a large
  workspace runs for hours (tens of files per second). Later pushes move
  only changed files.
- Submodules and nested repositories travel wholesale (only
  `always_exclude` applies inside them).
- A file rewritten with the same size within the same nanosecond is
  invisible, as it is to git.
- Nothing is merged. Two hosts editing the same unit between syncs end with
  one copy canonical and the other under `conflicts/`.

## Development

```bash
nix build .#handoff      # builds and runs the test suite (real git + rclone)
ruff check . && ruff format --check .
```
