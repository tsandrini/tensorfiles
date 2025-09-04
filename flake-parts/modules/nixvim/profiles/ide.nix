# --- flake-parts/modules/nixvim/profiles/ide.nix
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
{ localFlake }:
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimProfileLevel;

  cfg = config.tensorfiles.nixvim.profiles.ide;
  _ = mkOverrideAtNixvimProfileLevel;
in
{
  options.tensorfiles.nixvim.profiles.ide = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.nixvim = {
        profiles.graphical.enable = _ true;

        plugins = {
          # TODO [Copilot] Could not find agent.js (bad install?) : nil
          # editor.copilot-lua.enable = _ true;

          cmp.cmp.enable = _ true;
          cmp.lspkind.enable = _ true;
          cmp.schemastore.enable = _ true;

          lsp.lsp.enable = _ true;
          lsp.lsp.withKeymaps = _ false; # use lspsaga keymaps instead
          lsp.lspsaga.enable = _ true;
          lsp.sniprun.enable = _ true;

          lsp.conform.enable = _ true;
          lsp.fidget.enable = _ true;
          lsp.trouble.enable = _ true;
          lsp.otter.enable = _ true;
        };
      };

      plugins.direnv.enable = _ true;
      plugins.crates.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
