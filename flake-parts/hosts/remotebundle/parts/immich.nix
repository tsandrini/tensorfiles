# --- flake-parts/hosts/remotebundle/parts/immich.nix
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
  config,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";

  # --- database ---
  postgresVars = selfVars.services.postgresql;

  # --- immich ---
  immichVars = infraVars.hosts."remotebundle".services.immich;
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

  services.immich = {
    enable = true;
    inherit (immichVars) port;
    accelerationDevices = null;
    database = {
      enable = true;
      createDB = false;
      host = "/run/postgresql";
      inherit (postgresVars.instances."immich") user;
      name = postgresVars.instances."immich".database;
    };
  };

  # HW acceleration
  users.users."${config.services.immich.user}".extraGroups = [
    "video"
    "render"
  ];

  services.prometheus.exporters = {
    #
  };

  age.secrets = {
    #
  };
}
