# --- modules/programs/dmenu.nix
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
{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit
    (tensorfiles.nixos)
    getUserCacheDir
    isPywalEnabled
    ;

  cfg = config.tensorfiles.programs.dmenu;
in {
  # TODO test dmenu-rs if it works or not
  # https://github.com/NixOS/nixpkgs/pull/223667
  options.tensorfiles.programs.dmenu = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the dmenu app launcher.
    '');

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {
        pywal = {enable = mkPywalEnableOption;};

        pkg = mkOption {
          type = package;
          default = pkgs.dmenu;
          description = mdDoc ''
            Which package to use for the dmenu binaries. You can provide any
            custom derivation of your choice as long as the main binaries
            reside at

            - `$pkg/bin/dmenu`
            - `$pkg/bin/dmenu_run`
            - etc...
          '';
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings."${_user}";
        cacheDir = getUserCacheDir {
          inherit _user;
          cfg = config;
        };
        dmenu-pywaled = let
          name = "dmenu_run";
          buildInputs = [
            # This is fine since nix is a lazy language and dmenu-pywaled won't
            # get evaluated unless `isPywalEnabled == true`
            config.tensorfiles.programs.pywal.home.settings.${_user}.pkg
          ];
          script = pkgs.writeShellScriptBin name ''
            . "${cacheDir}/wal/colors.sh"

            ${userCfg.pkg}/bin/dmenu_run -nb "$color0" -nf "$color15" -sb "$color1" -sf "$color15"
          '';
        in
          pkgs.symlinkJoin {
            inherit name;
            paths = [script userCfg.pkg] ++ buildInputs;
            buildInputs = [pkgs.makeWrapper];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
          };
      in {
        home.packages = [
          (
            if (userCfg.pywal.enable && (isPywalEnabled config))
            then dmenu-pywaled
            else userCfg.pkg
          )
        ];
      });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
