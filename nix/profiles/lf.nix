# --- profiles/lf.nix
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

{ config, pkgs, lib, inputs, user, ... }:

let
  _ = lib.mkOverride 500;
in {

  home-manager.users.${user} = {

    programs.lf = {
      enable = _ true;
      settings = {
        ifs = _ "\n";
        filesep = _ "\n";
        icons = _ true;
        ignorecase = _ true;
        drawbox = _ true;
      };
      commands = {
        mkdir = "%mkdir -p \"$1\"";
        touch = "%touch \"$1\"";
        open = ''
          ''${{
              case $(file --mime-type "$f" -bL) in
                  text/*|application/json) $EDITOR "$f";;
                  *) xdg-open "$f" ;;
              esac
             }}
         '';
        unarchive = ''
          ''${{
            case "$f" in
                *.zip) unzip "$f" ;;
                *.tar.gz) tar -xzvf "$f" ;;
                *.tar.bz2) tar -xjvf "$f" ;;
                *.tar) tar -xvf "$f" ;;
                *) echo "Unsupported format" ;;
            esac
            }}
        '';
        zip = "%zip -r \"$f\" \"$f\"";
        tar = "%tar cvf \"$f.tar\" \"$f\"";
        targz = "%tar cvzf \"$f.tar.gz\" \"$f\"";
        tarbz2 = "%tar cjvf \"$f.tar.bz2\" \"$f\"";
      };
      keybindings = {
        m = null;
        o = null;
        n = null;
        "'" = null;
        d = null;
        c = null;
        e = null;
        f = null;
        "." = "set hidden!";
        dD = "delete";
        p = "paste";
        x = "cut";
        y = "copy";
        "<enter>" = "open";
        r = _ "rename";
        gg = _ "top";
        G = _ "bottom";
        R = _ "reload";
        C = "clear";
        U = "unselect";
      };
    };
  };
}
