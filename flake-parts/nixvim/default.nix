# --- flake-parts/nixvim/default.nix
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
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (inputs.flake-parts.lib) importApply mkPerSystemOption;

  mkNixvimConfiguration =
    name: pkgs:
    {
      extraSpecialArgs ? { },
      extraModules ? [ ],
      configImportArgs ? { },
    }:
    {
      inherit pkgs extraSpecialArgs;
      module =
        { ... }:
        {
          imports = [
            (importApply ./${name} configImportArgs)
          ] ++ extraModules ++ (lib.attrValues config.flake.nixvimModules);
        };
    };
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.nixvimConfigurations = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      default = { };
    };
  });

  config = {
    perSystem =
      {
        pkgs,
        config,
        system,
        ...
      }:
      let
        inherit (inputs.nixvim.lib.${system}.check) mkTestDerivationFromNixvimModule;
        inherit (inputs.nixvim.legacyPackages.${system}) makeNixvimWithModule;
      in
      {
        nixvimConfigurations = {
          vanilla-config = mkNixvimConfiguration "vanilla-config" pkgs { };
          base-config = mkNixvimConfiguration "base-config" pkgs { };
          minimal-config = mkNixvimConfiguration "minimal-config" pkgs { };
          graphical-config = mkNixvimConfiguration "graphical-config" pkgs { };
          ide-config = mkNixvimConfiguration "ide-config" pkgs { };
        };

        packages = {
          nvim = config.packages.nvim-ide-config;

          nvim-vanilla-config = makeNixvimWithModule config.nixvimConfigurations."vanilla-config";
          nvim-base-config = makeNixvimWithModule config.nixvimConfigurations."base-config";
          nvim-minimal-config = makeNixvimWithModule config.nixvimConfigurations."minimal-config";
          nvim-graphical-config = makeNixvimWithModule config.nixvimConfigurations."graphical-config";
          nvim-ide-config = makeNixvimWithModule config.nixvimConfigurations."ide-config";
        };

        checks = {
          nvim-vanilla-config = mkTestDerivationFromNixvimModule config.nixvimConfigurations."vanilla-config";
          nvim-base-config = mkTestDerivationFromNixvimModule config.nixvimConfigurations."base-config";
          nvim-minimal-config = mkTestDerivationFromNixvimModule config.nixvimConfigurations."minimal-config";
          nvim-graphical-config =
            mkTestDerivationFromNixvimModule
              config.nixvimConfigurations."graphical-config";
          nvim-ide-config = mkTestDerivationFromNixvimModule config.nixvimConfigurations."ide-config";
        };
      };
  };
}
