# --- flake-parts/agenix/secrets/secrets.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
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
let
  spinorbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1693g0EVyChehwAjJqkKLWD8ZysLbo9TbRZ2B9BcKe root@spinorbundle";
  jetbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQpLfZTRGfeVkh0tTCZ7Ads5fwYnl3cIj34Fukkymhp root@jetbundle";
  remotebundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/zORD7glqIeAJNnoW7PFKmZV1eJr46glrSvFDyWH2/ root@nixos";

  tsandrini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWrK27cm+rAVKuwDjlJgCuy8Rftg2YOALwtnu7z3Ox1 tsandrini";
in
{
  # ----------
  # | COMMON |
  # ----------
  # "common/accounts/tomas-dot-sandrini-at-seznam-dot-cz.age".publicKeys = [ tsandrini ];
  # "common/accounts/wareczech-at-gmail-dot-com.age".publicKeys = [ tsandrini ];

  # ---------
  # | HOSTS |
  # ---------

  # jetbundle
  "hosts/jetbundle/users/root/system-password.age".publicKeys = [ jetbundle ] ++ [ tsandrini ];
  "hosts/jetbundle/users/tsandrini/system-password.age".publicKeys = [ jetbundle ] ++ [ tsandrini ];

  # remotebundle
  "hosts/remotebundle/users/root/system-password.age".publicKeys = [ remotebundle ] ++ [ tsandrini ];
  "hosts/remotebundle/users/tsandrini/system-password.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/t-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/business-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/security-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/shopping-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/newsletters-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/rspamd-ui-basic-auth-file.age".publicKeys = [
    remotebundle
  ] ++ [ tsandrini ];

  # spinorbundle
  "hosts/spinorbundle/users/root/system-password.age".publicKeys = [ spinorbundle ] ++ [ tsandrini ];
  "hosts/spinorbundle/users/tsandrini/system-password.age".publicKeys = [
    spinorbundle
  ] ++ [ tsandrini ];
}
