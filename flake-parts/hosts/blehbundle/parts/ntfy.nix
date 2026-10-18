# --- flake-parts/hosts/blehbundle/parts/ntfy.nix
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
#
# ntfy push server for ccdash phone notifications. Everything is denied by
# default; users, ACL entries and tokens are provisioned from the agenix env
# file (`NTFY_AUTH_USERS`, `NTFY_AUTH_ACCESS`, `NTFY_AUTH_TOKENS`).
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
  # --- nginx ---
  nginxVars = infraVars.hosts."blehbundle".services.nginx;
  virtualHostsVar = nginxVars.virtualHosts;
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

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.age.secrets."hosts/${hostName}/ntfy-env".path;
    settings = {
      base-url = "https://${virtualHostsVar."ntfy".domain}";
      listen-http = virtualHostsVar."ntfy".proxyEndpoint;
      behind-proxy = true;
      auth-default-access = "deny-all";
    };
  };

  age.secrets = {
    "hosts/${hostName}/ntfy-env" = {
      file = "${secretsPath}/hosts/${hostName}/ntfy-env.age";
    };
  };
}
