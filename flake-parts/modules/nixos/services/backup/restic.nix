# --- flake-parts/modules/nixos/services/backup/restic.nix
#
# Author:  tsandrini <t@tsandrini.sh>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
{
  localFlake,
  infraVars,
  secretsPath,
  pubkeys,
}:
{
  config,
  lib,
  pkgs,
  system,
  hostName,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    mkPackageOption
    types
    attrValues
    concatLists
    concatMapStrings
    concatStrings
    concatStringsSep
    drop
    elemAt
    escapeShellArg
    literalExpression
    mapAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
    optional
    optionalAttrs
    optionals
    splitString
    stringLength
    substring
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkAgenixEnableOption;

  cfg = config.tensorfiles.services.backup.restic;
  _ = mkOverrideAtModuleLevel;

  agenixCheck = (isModuleLoadedAndEnabled config "tensorfiles.security.agenix") && cfg.agenix.enable;

  box = cfg.storageBox;
  sshAlias = "restic-storagebox";

  secretName = {
    password = "restic-backup-password";
    sshKey = "restic-backup-ssh-key";
    adminPassword = repoName: "restic-admin-${repoName}-password";
    adminSshKey = "restic-admin-ssh-key";
  };

  # NOTE: the Storage Box whitelists `rclone serve restic --stdio` (`-q` drops
  # its "config file not found" NOTICE); keys with a forced command ignore
  # whatever command is requested.
  rcloneOptions = keyFile: {
    "rclone.program" =
      "${lib.getExe' config.programs.ssh.package "ssh"} -i ${keyFile} -o BatchMode=yes -o ServerAliveInterval=60 ${sshAlias}";
    "rclone.args" = "rclone serve restic --stdio -q";
  };
  # `services.restic.backups.*.extraOptions` format (single-quoted values)
  toExtraOptions = opts: mapAttrsToList (k: v: "${k}='${v}'") opts;

  repoUrl = path: "rclone:${path}";

  # --- storage box authorized_keys ---
  chunksOf =
    n: s:
    if stringLength s <= n then [ s ] else [ (substring 0 n s) ] ++ chunksOf n (substring n (-1) s);

  # Port 22 (SFTP only) reads RFC4716 entries, port 23 reads OpenSSH entries.
  toRfc4716 =
    key:
    let
      parts = splitString " " key;
    in
    ''
      ---- BEGIN SSH2 PUBLIC KEY ----
      Comment: "${concatStringsSep " " (drop 2 parts)}"
      ${concatStringsSep "\n" (chunksOf 70 (elemAt parts 1))}
      ---- END SSH2 PUBLIC KEY ----
    '';

  # NOTE: append-only keys must never get an RFC4716 twin -- port 22 ignores
  # `command=`, which would turn them into full-access keys.
  authorizedKeysFile = pkgs.writeText "storagebox-authorized-keys" (
    concatMapStrings (key: "${key}\n" + toRfc4716 key) cfg.admin.authorizedKeys.fullAccess
    + concatStrings (
      mapAttrsToList (
        repoName: key:
        ''command="rclone serve restic --stdio --append-only -q ${box.repositoryRoot}/${repoName}",restrict ${key}''
        + "\n"
      ) cfg.admin.authorizedKeys.appendOnly
    )
  );

  # --- backupctl config (flake-parts/pkgs/backupctl/README.md) ---
  ownRepository = optionalAttrs cfg.enable {
    ${hostName} = {
      repository = repoUrl cfg.repositoryPath;
      inherit (cfg) passwordFile appendOnly;
      options = rcloneOptions cfg.sshKeyFile;
      replica = null;
    };
  };

  adminRepositories = optionalAttrs cfg.admin.enable (
    mapAttrs (repoName: repo: {
      repository = repoUrl repo.path;
      inherit (repo) passwordFile;
      options = rcloneOptions cfg.admin.sshKeyFile;
      replica = if cfg.admin.replicaPath != null then "${cfg.admin.replicaPath}/${repoName}" else null;
      appendOnly = false;
    }) cfg.admin.repositories
  );

  backupctlConfig = (pkgs.formats.json { }).generate "backupctl-config.json" {
    restic = lib.getExe cfg.package;
    ssh = lib.getExe' config.programs.ssh.package "ssh";
    sftp = lib.getExe' config.programs.ssh.package "sftp";
    inherit sshAlias;
    inherit (cfg) browseDirectory;
    authorizedKeysFile = if cfg.admin.enable then "${authorizedKeysFile}" else null;
    replicaRoot = if cfg.admin.enable then cfg.admin.replicaPath else null;
    handoff = if cfg.admin.handoff.enable then lib.getExe cfg.admin.handoff.package else null;
    inherit (cfg.admin) retention checkReadDataSubset;
    # full access wins if a host also administers its own repository
    repositories = ownRepository // adminRepositories;
  };

  notifyEmailUnit = "restic-notify-email";

  repositorySubmodule =
    { name, ... }:
    {
      options = {
        path = mkOption {
          type = types.str;
          default = "${box.repositoryRoot}/${name}";
          defaultText = literalExpression ''"''${storageBox.repositoryRoot}/<name>"'';
          description = "Repository path on the Storage Box.";
        };

        passwordSecretsPath = mkOption {
          type = types.str;
          default = "common/backup/restic-${name}-password";
          description = ''
            Path (relative to the agenix secrets directory, without the `.age`
            suffix) of the repository password.
          '';
        };

        passwordFile = mkOption {
          type = types.nullOr types.str;
          default = if agenixCheck then config.age.secrets.${secretName.adminPassword name}.path else null;
          defaultText = literalExpression "config.age.secrets.\"restic-admin-<name>-password\".path";
          description = ''
            File holding the repository password. Taken from agenix
            (`passwordSecretsPath`) when agenix is enabled.
          '';
        };
      };
    };
in
{
  options.tensorfiles.services.backup.restic = {
    enable = mkEnableOption ''
      Enables NixOS module that backs the host up into its own restic
      repository on a Hetzner Storage Box.

      The host logs in with a dedicated key that the Storage Box locks to
      `rclone serve restic --append-only <repository>`, so the host can add
      snapshots but can neither delete nor rewrite existing ones -- a
      compromised host cannot take its backups down with it. Deleting old
      snapshots is left to `backupctl maintain` on a host with `admin.enable`.

      Every run first takes a fresh plain-SQL dump of PostgreSQL (if
      enabled), then backs up the configured paths, so a restore always has a
      database no newer than the files next to it.

      Also installs `backupctl` (`status`, `browse`, `restic`) configured for
      this host's repository; run it as root, the secrets are root-owned.
    '';

    package = mkPackageOption pkgs "restic" { };

    cliPackage = mkOption {
      type = types.package;
      default = localFlake.packages.${system}.backupctl;
      defaultText = literalExpression "tensorfiles.packages.\${system}.backupctl";
      description = "The `backupctl` package, see `flake-parts/pkgs/backupctl`.";
    };

    agenix = {
      enable = mkAgenixEnableOption;
    };

    storageBox = {
      host = mkOption {
        type = types.str;
        default = infraVars.hosts."storagebundle-1".host;
        defaultText = "${infraVars.hosts."storagebundle-1".host}";
        description = "Hostname of the Hetzner Storage Box holding the repositories.";
      };

      port = mkOption {
        type = types.port;
        default = infraVars.hosts."storagebundle-1".port;
        defaultText = "${infraVars.hosts."storagebundle-1".port}";
        description = ''
          SSH port of the Storage Box. Has to be 23 -- only that port offers
          the `rclone serve restic` backend and honours `command=` restrictions.
        '';
      };

      user = mkOption {
        type = types.str;
        default = infraVars.hosts."storagebundle-1".user;
        defaultText = "${infraVars.hosts."storagebundle-1".user}";
        description = "Storage Box (sub-)account to log in as.";
      };

      repositoryRoot = mkOption {
        type = types.str;
        default = infraVars.hosts."storagebundle-1".repositoryRoot;
        defaultText = "${infraVars.hosts."storagebundle-1".repositoryRoot}";
        description = ''
          Directory on the Storage Box, relative to the account home, that
          holds one restic repository per backed-up host.
        '';
      };

      hostKey = mkOption {
        type = types.str;
        default = pubkeys.common.backup.storageBox.hostKey;
        defaultText = literalExpression "pubkeys.common.backup.storageBox.hostKey";
        description = "Pinned SSH host key of the Storage Box.";
      };
    };

    repositoryPath = mkOption {
      type = types.str;
      default = "${box.repositoryRoot}/${hostName}";
      defaultText = literalExpression ''"''${storageBox.repositoryRoot}/''${hostName}"'';
      description = ''
        Repository path on the Storage Box. Only informative for an append-only
        key, whose forced command pins the repository anyway, but used
        verbatim by keys without one.
      '';
    };

    appendOnly = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether this host's key is append-only on the Storage Box (see
        `pubkeys.common.backup.storageBox.appendOnly`). Only informs
        `backupctl`, which then refuses `maintain` instead of failing midway.
      '';
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "/var/lib/immich/library"
        "/var/vmail"
      ];
      description = ''
        Paths to back up. Every path has to exist, restic fails the whole run
        otherwise. The PostgreSQL dump and the SSH host keys are added
        automatically, see `postgresql.enable` and `includeSshHostKeys`.
      '';
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/var/lib/forgejo/data/indexers" ];
      description = "Exclude patterns, passed to `restic backup --exclude`.";
    };

    includeSshHostKeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to back up the SSH host keys. They are the host's agenix
        identity, so restoring them makes all secrets decryptable again
        without re-keying.
      '';
    };

    postgresql = {
      enable = mkOption {
        type = types.bool;
        default = config.services.postgresql.enable;
        defaultText = literalExpression "config.services.postgresql.enable";
        description = ''
          Whether to dump all PostgreSQL databases (`pg_dumpall`, plain SQL)
          right before every run and include the dump. Plain SQL on purpose:
          compressed dumps change completely on every run and defeat restic's
          deduplication, restic compresses on its own.
        '';
      };

      dumpDirectory = mkOption {
        type = types.str;
        default = "/var/backup/restic-postgresql";
        description = "Directory holding the dump between runs.";
      };
    };

    timerConfig = mkOption {
      type = types.attrsOf types.anything;
      default = {
        OnCalendar = "*-*-* 00/6:00:00";
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
      description = "systemd timer settings of the backup runs.";
    };

    notifyEmail = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "monitoring@example.com";
      description = ''
        Address to mail the unit status and log to when a run fails. Needs a
        local `sendmail` (e.g. postfix).
      '';
    };

    browseDirectory = mkOption {
      type = types.str;
      default = "Backups";
      description = "Directory, relative to the home, that `backupctl browse` mounts into.";
    };

    passwordSecretsPath = mkOption {
      type = types.str;
      default = "common/backup/restic-${hostName}-password";
      description = ''
        Path (relative to the agenix secrets directory, without the `.age`
        suffix) of the repository password. Shared with the hosts that
        administer the repository.
      '';
    };

    passwordFile = mkOption {
      type = types.nullOr types.str;
      default = if agenixCheck then config.age.secrets.${secretName.password}.path else null;
      defaultText = literalExpression "config.age.secrets.restic-backup-password.path";
      description = ''
        File holding the repository password. Taken from agenix
        (`passwordSecretsPath`) when agenix is enabled.
      '';
    };

    sshKeySecretsPath = mkOption {
      type = types.str;
      default = "hosts/${hostName}/backup-storagebox-client-ssh-key";
      description = ''
        Path (relative to the agenix secrets directory, without the `.age`
        suffix) of the private SSH key. Its public half belongs into
        `pubkeys.common.backup.storageBox.appendOnly.<hostName>`.
      '';
    };

    sshKeyFile = mkOption {
      type = types.nullOr types.str;
      default = if agenixCheck then config.age.secrets.${secretName.sshKey}.path else null;
      defaultText = literalExpression "config.age.secrets.restic-backup-ssh-key.path";
      description = ''
        Private SSH key used to log in to the Storage Box. Taken from agenix
        (`sshKeySecretsPath`) when agenix is enabled.
      '';
    };

    admin = {
      enable = mkEnableOption ''
        Configures `backupctl` for administering the Storage Box repositories
        with a full-access key. Everything is run by hand, nothing is
        scheduled: `backupctl status | browse | replicate | maintain |
        sync-keys | restic`, see `backupctl --help`.
      '';

      user = mkOption {
        type = types.str;
        example = "tsandrini";
        description = "User owning the secrets and so running `backupctl`.";
      };

      repositories = mkOption {
        type = types.attrsOf (types.submodule repositorySubmodule);
        default = { };
        example = {
          blehbundle = { };
        };
        description = "Repositories to administer, keyed by the backed-up host name.";
      };

      handoff = {
        enable = mkEnableOption ''
          Makes `backupctl status` report the `handoff` relay (dirty working
          trees carried between hosts, see `flake-parts/pkgs/handoff`) as one
          more informative row. `handoff` runs as the invoking user and reads
          that user's handoff config.
        '';

        package = mkOption {
          type = types.package;
          default = localFlake.packages.${system}.handoff;
          defaultText = literalExpression "tensorfiles.packages.\${system}.handoff";
          description = "The `handoff` package.";
        };
      };

      replicaPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/mnt/hdd-backup/restic";
        description = ''
          Directory holding local replica repositories
          (`<replicaPath>/<repository>`), filled by `backupctl replicate`.
          `null` disables the replicas. On a removable disk, mount it with
          `x-systemd.automount` -- otherwise an absent disk means the directory
          gets created on the parent filesystem.
        '';
      };

      retention = mkOption {
        type = types.listOf types.str;
        default = [
          "--keep-last=8"
          "--keep-daily=14"
          "--keep-weekly=8"
          "--keep-monthly=12"
          "--keep-yearly=3"
        ];
        description = "`restic forget` policy applied by `backupctl maintain`.";
      };

      checkReadDataSubset = mkOption {
        type = types.str;
        default = "5%";
        description = "Share of pack data read and verified by `backupctl maintain`.";
      };

      sshKeySecretsPath = mkOption {
        type = types.str;
        default = "hosts/${hostName}/backup-storagebox-admin-ssh-key";
        description = ''
          Path (relative to the agenix secrets directory, without the `.age`
          suffix) of the full-access private SSH key. Its public half has to
          be in `authorizedKeys.fullAccess`.
        '';
      };

      sshKeyFile = mkOption {
        type = types.nullOr types.str;
        default = if agenixCheck then config.age.secrets.${secretName.adminSshKey}.path else null;
        defaultText = literalExpression "config.age.secrets.restic-admin-ssh-key.path";
        description = ''
          Full-access private SSH key. Taken from agenix (`sshKeySecretsPath`)
          when agenix is enabled.
        '';
      };

      authorizedKeys = {
        fullAccess = mkOption {
          type = types.listOf types.str;
          default = pubkeys.common.backup.storageBox.fullAccess;
          defaultText = literalExpression "pubkeys.common.backup.storageBox.fullAccess";
          description = ''
            Full-access keys, rendered in both the OpenSSH (port 23) and the
            RFC4716 (port 22) format.
          '';
        };

        appendOnly = mkOption {
          type = types.attrsOf types.str;
          default = pubkeys.common.backup.storageBox.appendOnly;
          defaultText = literalExpression "pubkeys.common.backup.storageBox.appendOnly";
          description = ''
            Append-only keys keyed by repository name, rendered in the OpenSSH
            format only, each locked to its own repository.
          '';
        };
      };
    };
  };

  config = mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.enable || cfg.admin.enable) {
      environment.systemPackages = [ cfg.cliPackage ];
      environment.etc."backupctl/config.json".source = _ backupctlConfig;

      programs.ssh = {
        extraConfig = ''
          Host ${sshAlias}
            HostName ${box.host}
            Port ${toString box.port}
            User ${box.user}
            HostKeyAlias ${sshAlias}
            IdentitiesOnly yes
        '';
        knownHosts.${sshAlias}.publicKey = _ box.hostKey;
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.passwordFile != null && cfg.sshKeyFile != null;
          message = "tensorfiles.services.backup.restic: set `passwordFile` and `sshKeyFile` (or enable agenix).";
        }
        {
          assertion = cfg.notifyEmail == null || config.services.mail.sendmailSetuidWrapper != null;
          message = "tensorfiles.services.backup.restic.notifyEmail needs a local sendmail.";
        }
      ];

      services.restic.backups.storagebox = {
        package = _ cfg.package;
        repository = _ (repoUrl cfg.repositoryPath);
        passwordFile = _ cfg.passwordFile;
        extraOptions = _ (toExtraOptions (rcloneOptions cfg.sshKeyFile));
        paths = _ (
          cfg.paths
          ++ optional cfg.postgresql.enable cfg.postgresql.dumpDirectory
          ++ optionals cfg.includeSshHostKeys (
            concatLists (
              map (key: [
                key.path
                "${key.path}.pub"
              ]) config.services.openssh.hostKeys
            )
          )
        );
        exclude = _ cfg.exclude;
        extraBackupArgs = _ [
          "--exclude-caches"
          "--retry-lock=1h"
        ];
        timerConfig = _ cfg.timerConfig;
        # NOTE: init is a create-only operation, allowed by the append-only key
        initialize = _ true;
        pruneOpts = _ [ ];
        runCheck = _ false;
        # NOTE: superseded by `backupctl restic <hostName>`
        createWrapper = _ false;
        # NOTE: `set -e` is not inherited, a failed dump must not replace the last good one
        backupPrepareCommand = mkIf cfg.postgresql.enable (_ ''
          set -euo pipefail
          install -d -m 0700 ${cfg.postgresql.dumpDirectory}
          ${pkgs.util-linux}/bin/runuser -u postgres -- \
            ${config.services.postgresql.package}/bin/pg_dumpall \
            >${cfg.postgresql.dumpDirectory}/all.sql.tmp
          mv ${cfg.postgresql.dumpDirectory}/all.sql.tmp ${cfg.postgresql.dumpDirectory}/all.sql
        '');
      };

      # NOTE: unit owned by the upstream restic module, lists stay mergeable
      systemd.services.restic-backups-storagebox = {
        after = optional cfg.postgresql.enable "postgresql.service";
        onFailure = optional (cfg.notifyEmail != null) "${notifyEmailUnit}@%n.service";
        serviceConfig = {
          CPUSchedulingPolicy = _ "idle";
          IOSchedulingClass = _ "idle";
        };
      };

      systemd.services."${notifyEmailUnit}@" = mkIf (cfg.notifyEmail != null) {
        description = _ "Mail about the failed unit %i";
        scriptArgs = _ "%i";
        path = _ [ pkgs.systemd ];
        script = _ ''
          {
            printf 'Subject: [%s] %s failed\nTo: %s\n\n' ${escapeShellArg hostName} "$1" ${escapeShellArg cfg.notifyEmail}
            systemctl status --no-pager --full "$1" || true
          } | ${config.security.wrapperDir}/sendmail -t
        '';
        serviceConfig.Type = _ "oneshot";
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.enable && agenixCheck) {
      age.secrets = {
        ${secretName.password}.file = _ (secretsPath + "/${cfg.passwordSecretsPath}.age");
        ${secretName.sshKey}.file = _ (secretsPath + "/${cfg.sshKeySecretsPath}.age");
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.admin.enable {
      assertions = [
        {
          assertion = cfg.admin.repositories != { };
          message = "tensorfiles.services.backup.restic.admin: no `repositories` to administer.";
        }
        {
          assertion =
            cfg.admin.sshKeyFile != null
            && builtins.all (repo: repo.passwordFile != null) (attrValues cfg.admin.repositories);
          message = "tensorfiles.services.backup.restic.admin: set `sshKeyFile` and every `repositories.*.passwordFile` (or enable agenix).";
        }
      ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.admin.enable && agenixCheck) {
      age.secrets = {
        ${secretName.adminSshKey} = {
          file = _ (secretsPath + "/${cfg.admin.sshKeySecretsPath}.age");
          owner = _ cfg.admin.user;
        };
      }
      // mapAttrs' (
        repoName: repo:
        nameValuePair (secretName.adminPassword repoName) {
          file = _ (secretsPath + "/${repo.passwordSecretsPath}.age");
          owner = _ cfg.admin.user;
        }
      ) cfg.admin.repositories;
    })
    # |----------------------------------------------------------------------| #
  ];

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
