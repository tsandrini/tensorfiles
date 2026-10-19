# --- flake-parts/hosts/pupibundle/parts/intranet-tls.nix
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
# The `*.home.tsandrini.sh` wildcard certificate (Wedos DNS-01), shared by
# every intranet vhost on this host through `useACMEHost`. Waits for the
# Wedos API secret.
{
  secretsPath,
  infraVars,
}:
{
  config,
  lib,
  hostName,
  ...
}:
let
  nginxVars = infraVars.hosts."blehbundle".services.nginx;

  wedosEnv = "hosts/${hostName}/wedos-acme-env";
  wedosEnvFile = "${secretsPath}/${wedosEnv}.age";
in
lib.mkIf (builtins.pathExists wedosEnvFile) {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = infraVars.common.contacts.securityEmail;
      dnsProvider = "wedos";
      dnsResolver = "ns.wedos.net:53";
      environmentFile = config.age.secrets."${wedosEnv}".path;
      dnsPropagationCheck = true;
    };
    certs."${nginxVars.intranetDomain}" = {
      inherit (config.services.nginx) group;
      domain = nginxVars.intranetDomain;
      extraDomainNames = [ "*.${nginxVars.intranetDomain}" ];
      reloadServices = [ "nginx.service" ];
    };
  };

  age.secrets."${wedosEnv}".file = wedosEnvFile;

  # NOTE: Wedos allowlists WAPI clients by source address and the Pi's
  # outgoing IPv6 is a rotating temporary one; IPv4 only, so lego always
  # comes from the allowlisted home address
  systemd.services."acme-order-renew-${nginxVars.intranetDomain}".serviceConfig.RestrictAddressFamilies =
    lib.mkForce [
      "AF_INET"
      "AF_NETLINK"
      "AF_UNIX"
    ];
}
