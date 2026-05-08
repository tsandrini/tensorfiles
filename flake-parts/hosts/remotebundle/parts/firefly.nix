# --- flake-parts/hosts/remotebundle/parts/firefly.nix
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
  config,
  hostName,
  ...
}:
let
  # selfVars = infraVars.hosts."${hostName}";

  # --- nginx ---
  nginxVars = infraVars.hosts."remotebundle".services.nginx;

  domain = nginxVars.primaryDomain;
  fireflyDomain = "firefly.${domain}";
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

  # Add firefly-pico and firefly-importer
  services.firefly-iii = {
    enable = true;
    virtualHost = fireflyDomain;
    enableNginx = true;
    settings = {
      APP_KEY_FILE = config.age.secrets."hosts/${hostName}/firefly-iii-app-key".path;
      APP_URL = "https://${config.services.firefly-iii.virtualHost}";
      DB_CONNECTION = "pgsql";
      DB_HOST = "/run/postgresql";
      SITE_OWNER = "t@${domain}";
      TZ = "Europe/Prague";
    };
  };

  services.firefly-pico = {
    enable = true;
    enableNginx = true;
    virtualHost = "firefly-pico.${domain}";
    settings = {
      APP_URL = "https://${config.services.firefly-pico.virtualHost}";
      TZ = "Europe/Berlin";
      FIREFLY_URL = config.services.firefly-iii.settings.APP_URL;
      SITE_OWNER = "t@${domain}";
      # APP_KEY_FILE = config.age.secrets.firefly-pico-app-key.path;
    };
  };

  services.prometheus.exporters = {
    #
  };

  age.secrets = {
    "hosts/${hostName}/firefly-iii-app-key" = {
      file = "${secretsPath}/hosts/${hostName}/firefly-iii-app-key.age";
      owner = config.services.firefly-iii.user;
    };
  };
}
