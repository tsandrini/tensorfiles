# --- flake-parts/hosts/remotebundle/parts/forgejo.nix
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
  infraVars,
}:
{
  pkgs,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";

  # --- database ---
  postgresVars = selfVars.services.postgresql;

  # --- nginx ---
  nginxVars = infraVars.hosts."remotebundle".services.nginx;
  virtualHostsVar = nginxVars.virtualHosts;

  # --- forgejo ---
  forgejoVars = infraVars.hosts."remotebundle".services.forgejo;
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
        #
      ];
    };
  };

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    database = {
      createDatabase = false;
      type = "postgres";
      socket = "/run/postgresql";
      inherit (postgresVars.instances."forgejo") user;
      name = postgresVars.instances."forgejo".database;
    };
    settings = {
      server = {
        HTTP_PORT = forgejoVars.server.http_port;
        HTTP_ADDR = forgejoVars.server.http_addr;

        ROOT_URL = "https://${virtualHostsVar."forgejo".domain}/";
        DOMAIN = virtualHostsVar."forgejo".domain;
        SSH_PORT = infraVars.common.services.openssh.defaultPort;
        LANDING_PAGE = "explore";
      };
      service = {
        DISABLE_REGISTRATION = true;
        COOKIE_SECURE = true;
        ENABLE_NOTIFY_MAIL = true;
        REGISTER_EMAIL_CONFIRM = true;
      };
      indexer = {
        REPO_INDEXER_ENABLED = true;
      };
      mailer = {
        ENABLED = true;
        PROTOCOL = "smtp";
        SMTP_ADDR = "localhost";
        FROM = "git-bot@tsandrini.sh";
      };
      DEFAULT = {
        APP_NAME = "tsandrini's git";
      };
    };
  };

  systemd.services.forgejo = {
    path = [ pkgs.system-sendmail ];
  };

  services.prometheus.exporters = {
    #
  };

  age.secrets = {
    #
  };
}
