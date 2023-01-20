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

  lf-previewer =
    let name = "lf-previewer";
        buildInputs = with pkgs; [
          lf-cleaner
          ueberzug
          mediainfo
          file
          libuchardet
          highlight
          libarchive
          unrar
          _7zz
          odt2txt
          w3m
          lynx
          catdoc
          python39Packages.docx2txt
          transmission
        ];
        # script = pkgs.writeShellScriptBin name (builtins.readFile ./lf-previewer);
        script = pkgs.writeShellScriptBin name ''
          case ''${1##*.} in
              a|ace|alz|apk|arc|arj|bz|bz2|cab|cpio|deb|gz|iso|jar|lha|lz|lzh|lzma|lzo|\
              rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip|zst)
                  bsdtar --list --file "$1" && exit ;;
              rar)
                  unrar lt -p- -- "$1" && exit ;;
              7z)
                  7z l -p -- "$1" && exit ;;
              pdf)
                  pdftotext -l 10 -nopgbrk -q -- "$1" - && exit ;;
              torrent)
                  transmission-show -- "$1" && exit ;;
              odt|ods|odp|sxw)
                  odt2txt "$1" && exit ;;
              doc)
                  catdoc "$1" && exit ;;
              docx)
                  docx2txt "$1" - && exit ;;
              htm|html|xhtml)
                  # Preview as text conversion
                  w3m -dump "$1" ||
                  lynx -dump -- "$1" ||
                  elinks -dump "$1" && exit ;;

              *) ;; # Go on to handle by mime type
          esac

          case "$(file -Lb --mime-type -- "$1")" in
              # Text
              text/*|*/xml|*/csv|*/json)
                  # try to detect the charactor encodeing
                  enc=$(head -n20 "$1" | uchardet)
                  head -n 100 "$1" |
                  { if command -v highlight > /dev/null 2>&1; then
                      highlight -O ansi --force
                  else
                      cat
                  fi } |
                  iconv -f "''${enc:-UTF-8}" -t UTF-8 && exit ;;

              image/*)
                  lf-cleaner draw "$1" "$2" "$3" "$4" "$5" && exit 1 ;;

              video/*|audio/*|application/octet-stream)
                  mediainfo "$1" && exit ;;

              *) ;; # Go on to fall back
          esac

          echo '----- File Type Classification -----'
          file --dereference --brief -- "$1"
        '';
    in pkgs.symlinkJoin {
      inherit name;
      paths = [ script ] ++ buildInputs;
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
    };

  lf-cleaner =
    let name = "lf-cleaner";
        buildInputs = with pkgs; [
          ueberzug
        ];
        script = pkgs.writeShellScriptBin name ''
          ID="lf-preview"
          [ -p "$FIFO_UEBERZUG" ] || exit 1

          case "''${1:-clear}" in
              draw)
                  {   printf '{ "action": "add", "identifier": "%s", "path": "%s",' "$ID" "$2"
                      printf '"width": %d, "height": %d, "x": %d, "y": %d }\n' "$3" "$4" "$5" "$6"
                  } > "$FIFO_UEBERZUG" ;;
              clear|*)
                  printf '{ "action": "remove", "identifier": "%s" }\n' "$ID" > "$FIFO_UEBERZUG" ;;
          esac
        '';
    in pkgs.symlinkJoin {
      inherit name;
      paths = [ script ] ++ buildInputs;
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
    };

  tensorlf =
    let name = "lf";
        buildInputs = with pkgs; [
          ueberzug
          lf-previewer
          lf-cleaner
        ];
        script = pkgs.writeShellScriptBin name ''
          start_ueberzug() {
              mkfifo "$FIFO_UEBERZUG" || exit 1
              ueberzug layer --parser json --silent < "$FIFO_UEBERZUG" &
              exec 3>"$FIFO_UEBERZUG"
          }

          stop_ueberzug() {
              exec 3>&-
              rm "$FIFO_UEBERZUG" > /dev/null 2>&1
          }

          if [ -n "$DISPLAY" ] && command -v ueberzug > /dev/null; then
              export FIFO_UEBERZUG="/tmp/lf-ueberzug-''${PPID}"
              trap stop_ueberzug EXIT QUIT INT TERM
              start_ueberzug
          fi

          exec ${pkgs.lf}/bin/lf "$@"
        '';
    in pkgs.symlinkJoin {
      inherit name;
      paths = [ script pkgs.lf ] ++ buildInputs;
    };

in {

  home-manager.users.${user} = {

    home.file.".config/lf/icons".source = ./icons;

    programs.lf = {
      enable = _ true;
      # Use `set previewer lf-previewer` instead since we can dynamically
      # inject the package into $PATH thanks to the wrapper
      #
      # previewer.source = ./lf-previewer;
      package = tensorlf;
      settings = {
        ifs = _ "\\n";
        filesep = _ "\\n";
        icons = _ true;
        ignorecase = _ true;
        drawbox = _ true;
      };
      extraConfig = ''
        set cleaner lf-cleaner
        set previewer lf-previewer
      '';
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
