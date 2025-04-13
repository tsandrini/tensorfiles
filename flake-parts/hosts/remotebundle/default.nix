# --- flake-parts/hosts/remotebundle/default.nix
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
{ inputs }:
{ pkgs, ... }:
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Model: Lenovo B51-80

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = with inputs; [ (vpsadminos + "/os/lib/nixos-container/vpsadminos.nix") ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [ ];

  # ----------------------------
  # | ADDITIONAL USER PACKAGES |
  # ----------------------------
  # home-manager.users.${user} = {home.packages = with pkgs; [];};

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------

  tensorfiles = {
    profiles.headless.enable = true;
    profiles.packages-base.enable = true;
    # profiles.packages-extra.enable = true;

    services.mailserver.enable = true;
    services.mailserver.roundcube.enable = true;
    services.mailserver.rspamd-ui.enable = true;

    services.networking.networkmanager.enable = false;
    security.agenix.enable = true;
    tasks.system-autoupgrade.enable = false;

    # Use the `nh` garbage collect to also collect .direnv and XDG profiles
    # roots instead of the default ones.
    tasks.nix-garbage-collect.enable = false;
    programs.nh.enable = true;

    system.users.usersSettings."root" = {
      agenixPassword.enable = true;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = true;
      extraGroups = [ "input" ];
    };
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.bash;

  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  # services.caddy = {
  #   enable = true;
  #   virtualHosts."tsandrini.sh".extraConfig = ''
  #     encode gzip
  #     file_server
  #     root * ${
  #       pkgs.runCommand "testdir" { } ''
  #         mkdir "$out"
  #         echo hello world > "$out/index.html"
  #       ''
  #     }
  #   '';
  # };

  # services.openssh.settings.permitrootlogin = "yes";
  #users.extrausers.root.openssh.authorizedkeys.keys =
  #  [ "..." ];

  systemd.extraConfig = ''
    DefaultTimeoutStartSec=900s
  '';

  home-manager.users."tsandrini" = {
    tensorfiles.hm = {

      profiles.headless.enable = true;
      security.agenix.enable = true;
    };

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.sessionVariables = {
      DEFAULT_USERNAME = "tsandrini";
      DEFAULT_MAIL = "t@tsandrini.sh";
    };
    programs.git.signing.key = "3E83AD690FA4F657";

    home.packages = with pkgs; [ ];
  };
}
