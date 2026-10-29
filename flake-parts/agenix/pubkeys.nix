# --- flake-parts/agenix/pubkeys.nix
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
let
  # spinorbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1693g0EVyChehwAjJqkKLWD8ZysLbo9TbRZ2B9BcKe root@spinorbundle";
  # jetbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQpLfZTRGfeVkh0tTCZ7Ads5fwYnl3cIj34Fukkymhp root@jetbundle";
  tsandrini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWrK27cm+rAVKuwDjlJgCuy8Rftg2YOALwtnu7z3Ox1 tsandrini";
  deploy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEKMF32cs/4ZtlrPNfFZyGZ7dLNaYZ+JKWpPSF1bwqqE deploy@tsandrini";
  # maya = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiElRBnJTDprJmK5zo4xM0mO0y83KwPJYfDwfWh58gm maya@balthasar";

  nix-remote-builder-flatbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/NqSHi0kMfd4hf14y2VxnQoaW+561MbI/CnM81aSFQ nix-remote-builder@flatbundle";

  restic-admin-flatbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQVLzUifJAI7NFgTXjxTS7OexmM/ipWEMxLtk9HInSW restic-admin-flatbundle";
  restic-client-remotebundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUsiIQboHD33Y1C5ut6JQ1ZL7PMMqa01oZUG2+4mVrp restic-client-remotebundle";
  restic-client-blehbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID03+HqMSNIKeldtNA5sZgppOaRf4p2TC4NoDFn4OLf0 restic-client-blehbundle";
  restic-client-pupibundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhpHRcnsno0QGRflS9tPIVwS4h58+hEhlWwmtnvQHX0 restic-client-pupibundle";
  restic-admin-navibundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII+BTTro7oxuAsWW2vEJIzGttDdfjmPoBmmi977ti/xU restic-admin-navibundle";
  restic-admin-krupikbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQFDsp9xADTOtxNKhvM+MLGys8pnjOQmDXiBOrOFK7r restic-admin-krupikbundle";
in
{
  common = {
    nixRemoteBuilders = [ nix-remote-builder-flatbundle ];

    # Rendered into the Storage Box `authorized_keys` by
    # `restic-storagebox-sync-keys` (tensorfiles.services.backup.restic.admin)
    backup.storageBox = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      fullAccess = [
        tsandrini
        restic-admin-flatbundle
        restic-admin-navibundle
        restic-admin-krupikbundle
      ];
      # each locked to `restic/<name>`
      appendOnly = {
        remotebundle = restic-client-remotebundle;
        blehbundle = restic-client-blehbundle;
        pupibundle = restic-client-pupibundle;
      };
    };
  };
  hosts = {
    storagebundle-1 = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      # NOTE: Go ssh clients (rclone) ask for RSA first; a known_hosts with only
      # the ed25519 key fails with "knownhosts: key mismatch"
      extraHostKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw=="
        "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==" # pragma: allowlist secret
      ];
    };
    navibundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID4CsU0/G4Qv5YXPfII/7cfXHoUxGmnCDXJKQjkIa0g3 root@navibundle";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [ tsandrini ];
        };
        deploy = {
          authorizedKeys = [ deploy ];
        };
      };
    };
    krupikbundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2uNUIA6VhPU2kjkK5dNOPzs9ic0oO0Bf5qHGJjzPRq root@krupikbundle";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [ tsandrini ];
        };
        deploy = {
          authorizedKeys = [ deploy ];
        };
      };
    };
    flatbundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8avUMhkJ8zQ6/uvLGGEhU6VZ00bNDR9nWko7Kk8pbX root@flatbundle";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [ tsandrini ];
        };
      };
    };
    jetbundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQpLfZTRGfeVkh0tTCZ7Ads5fwYnl3cIj34Fukkymhp root@jetbundle";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [ tsandrini ];
        };
      };
    };
    remotebundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/zORD7glqIeAJNnoW7PFKmZV1eJr46glrSvFDyWH2/ root@nixos";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [ tsandrini ];
        };
        mrpack = {
          authorizedKeys = [ tsandrini ];
        };
        deploy = {
          authorizedKeys = [
            deploy
          ];
        };
      };
    };
    blehbundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUem9jyfHkEN3DRNuS896ai1+Pu/vxiQrXoZw0cHxGH root@blehbundle";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [
            tsandrini
          ];
        };
        deploy = {
          authorizedKeys = [
            deploy
          ];
        };
      };
    };
    spinorbundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1693g0EVyChehwAjJqkKLWD8ZysLbo9TbRZ2B9BcKe root@spinorbundle";
    };
    pupibundle = {
      hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLvjzkKLhKbaRU/uf3A+pf25rir3y+6mvcbaAxt2DHP root@pupibundle";
      users = {
        root = {
          authorizedKeys = [ ];
        };
        tsandrini = {
          authorizedKeys = [ tsandrini ];
        };
        deploy = {
          authorizedKeys = [
            deploy
          ];
        };
      };
    };
  };
}
