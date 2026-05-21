# --- flake-parts/hosts/remotebundle/parts/mrpack-host.nix
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
{ infraVars }:
_:
let
  nginxVars = infraVars.hosts."remotebundle".services.nginx;
  packDomain = "mrpack.${nginxVars.primaryDomain}";

  packRoot = "/var/www/pack";
  packFiles = "${packRoot}/files";
in
{
  tensorfiles.system.users.usersSettings."mrpack" = {
    isSudoer = false;
    isNixTrusted = false;
  };

  users.users.mrpack = {
    isNormalUser = true;
    home = packRoot;
    createHome = false; # systemd-tmpfiles creates it below with the right mode
    group = "mrpack";
    description = "SFTP-only publisher for ${packDomain}";
  };
  users.groups.mrpack = { };

  systemd.tmpfiles.rules = [
    # chroot target: root-owned, world-readable, NOT writable by mrpack
    "d ${packRoot}  0755 root   root   -"
    # writable upload dir + nginx docroot
    "d ${packFiles} 0755 mrpack mrpack -"
  ];

  services.openssh.allowSFTP = true;

  services.nginx.virtualHosts."${packDomain}" = {
    enableACME = true;
    forceSSL = true;
    quic = true;
    http3 = true;

    root = packFiles;

    locations."/" = {
      extraConfig = ''
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
      '';
    };

    extraConfig = ''
      # Advertise HTTP/3 (matches mkPublicVhost convention in nginx-proxy.nix)
      add_header Alt-Svc 'h3=":443"; ma=86400' always;

      # Keep cache short so re-uploading the same filename is picked up
      # quickly by Prism / curl.
      add_header Cache-Control "public, max-age=60" always;

      # MIME types for the artifacts we serve.
      types {
        application/zip mrpack;
        application/zip zip;
      }
    '';
  };
}
