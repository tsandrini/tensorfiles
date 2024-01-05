# --- parts/modules/home-manager/programs/dmenu.nix
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
  self,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.dmenu;

  dmenu-pywaled = let
    name = "dmenu_run";
    buildInputs = [
      cfg.pkg
    ];
    script = pkgs.writeShellScriptBin name ''
      . "${config.xdg.cacheHome}/wal/colors.sh"

      ${cfg.pkg}/bin/dmenu_run -nb "$color0" -nf "$color15" -sb "$color1" -sf "$color15"
    '';
  in
    pkgs.symlinkJoin {
      inherit name;
      paths = [script cfg.pkg] ++ buildInputs;
      buildInputs = [pkgs.makeWrapper];
      postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
    };
in {
  options.tensorfiles.hm.programs.dmenu = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

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
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = [
        (
          if ((isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable)
          then dmenu-pywaled
          else cfg.pkg
        )
      ];
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
