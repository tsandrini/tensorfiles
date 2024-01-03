# --- parts/modules/home-manager/hardware/nixGL.nix
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
  inputs',
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.hardware.nixGL;
  _ = mkOverride 550;

  # TODO unfortunately nixGL doesnt have a mainprogram set
  nixGLWrap = pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "exec ${cfg.pkg}/bin/nixGL $bin \$@" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';
in {
  options.tensorfiles.hm.hardware.nixGL = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    pkg = mkOption {
      type = package;
      inherit (inputs'.nixGL.packages) default;
      description = ''
        NixGL binary that should be used for wrapping other graphical executables.
      '';
    };

    programPatches = {
      enable = mkEnableOption (mdDoc ''
        Enables the nixGL program patches
      '');

      kitty = mkAlreadyEnabledOption (mdDoc ''
        Enables the kitty executable wrapper
      '');
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = [cfg.pkg];
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.programPatches.enable (let
      kittyCheck = cfg.programPatches.kitty && (isModuleLoadedAndEnabled config "tensorfiles.hm.program.terminals.kitty");
    in {
      programs.kitty.package = mkIf kittyCheck (_ (nixGLWrap config.tensorfiles.hm.programs.terminals.kitty.pkg));
    }))
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
