# --- flake-parts/hosts/remotebundle/parts/postgres.nix
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
  secretsPath,
  infraVars,
}:
{
  pkgs,
  config,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";

  # --- monitoring ---
  monitoringVars = infraVars.hosts."remotebundle";
  prometheusExporters = monitoringVars.services.prometheus.exporters;

  # --- database ---
  postgresVars = selfVars.services.postgresql;
  pgadminVars = selfVars.services.pgadmin;
in
{
  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [ ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [ ];

  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
      allowedUDPPorts = [
        #
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        config.services.postgresql.settings.port
      ];
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      inherit (postgresVars) port;
      password_encryption = "scram-sha-256";
    };
    authentication = ''
      # Allow grafana user to connect via local socket with peer auth (no password)
      local   all potgres                                             peer
      local   all ${postgresVars.instances."grafana".user}            peer
      local   all ${postgresVars.instances."immich".user}             peer
      local   all ${postgresVars.instances."forgejo".user}            peer
      local   all ${postgresVars.instances."firefly-iii".user}        peer

      # Require SCRAM password for admin on local socket and TCP (IPv4 + IPv6)
      local   all             admin                                   scram-sha-256
      host    all             admin           127.0.0.1/32            scram-sha-256
      host    all             admin           ::1/128                 scram-sha-256

      # Optionally block all other users from connecting unless explicitly configured
      # local   all             all                                     reject
      # host    all             all             all                     reject
    '';
    ensureDatabases = [
      postgresVars.instances."grafana".database
      postgresVars.instances."immich".database
      postgresVars.instances."forgejo".database
      postgresVars.instances."firefly-iii".database
    ];
    ensureUsers = [
      {
        name = "admin";
        ensureClauses = {
          superuser = true;
          login = true;
          createrole = true;
          createdb = true;
        };
      }
      {
        name = postgresVars.instances."grafana".user;
        ensureDBOwnership = true;
      }
      {
        name = postgresVars.instances."forgejo".user;
        ensureDBOwnership = true;
      }
      {
        name = postgresVars.instances."firefly-iii".user;
        ensureDBOwnership = true;
      }
      {
        name = postgresVars.instances."immich".user;
        ensureDBOwnership = true;
      }
    ];
  };

  # systemd.services.postgresql.postStart = ''
  #   $PSQL -f ${pkgs.writeText "postgresql-post-init.sql" ''
  #     ALTER USER admin WITH PASSWORD 'SCRAM-SHA-256$4096:4ASEVqDlBNdjM7PKDkIYXg==$Y0n8toSrM6lgAzASCTCVq+UzxVEc3ANMCPYfEarQs88=:yVyYyjmUqUoLe26EXSQE4Zvo7B3me+3HcelupObpFf4=';
  #   ''}
  # '';

  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    compressionLevel = 11;
    backupAll = true;
  };

  services.pgadmin = {
    enable = false;
    inherit (pgadminVars) port;
    initialEmail = "t@tsandrini.sh";
    initialPasswordFile = config.age.secrets."hosts/${hostName}/pgadmin-admin-password".path;
  };

  services.prometheus.exporters = {
    postgres = {
      enable = true;
      inherit (prometheusExporters.postgres) port;
      runAsLocalSuperUser = true;
    };
  };

  age.secrets = {
    "hosts/${hostName}/pgadmin-admin-password" = {
      file = "${secretsPath}/hosts/${hostName}/pgadmin-admin-password.age";
    };
  };
}
