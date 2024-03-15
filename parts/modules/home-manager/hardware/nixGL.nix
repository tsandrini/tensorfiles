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
{ localFlake, inputs }:
{
  config,
  lib,
  pkgs,
  system,
  ...
}:
with builtins;
with lib;
let
  inherit (localFlake.lib) isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.hardware.nixGL;
  _ = mkOverride 550;

  # TODO unfortunately nixGL doesnt have a mainprogram set
  nixGLWrap =
    pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "exec ${lib.getExe' cfg.pkg "nixGL"} $bin \$@" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';

  kittyPatchCheck =
    cfg.programPatches.enable
    && cfg.programPatches.kitty
    && (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.terminals.kitty");
in
{
  options.tensorfiles.hm.hardware.nixGL = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    pkg = mkOption {
      type = package;
      inherit (inputs.nixGL.packages.${system}) default;
      description = ''
        NixGL binary that should be used for wrapping other graphical executables.
      '';
    };

    programPatches = {
      enable = mkEnableOption (mdDoc ''
        Enables the nixGL program patches
      '');

      kitty =
        mkEnableOption (mdDoc ''
          Enables the kitty executable wrapper
        '')
        // {
          default = true;
        };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    { home.packages = [ cfg.pkg ]; }
    # |----------------------------------------------------------------------| #
    (mkIf kittyPatchCheck {
      programs.kitty.package = _ (nixGLWrap config.tensorfiles.hm.programs.terminals.kitty.pkg);
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
