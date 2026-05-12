# --- flake-parts/modules/nixvim/plugins/lsp/none-ls.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.lsp.none-ls;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.lsp.none-ls = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      # none-ls hosts external linters/formatters that don't ship as LSPs —
      # exposed to nvim through the standard LSP diagnostic/code-action APIs.
      # Used here purely for Nix static analysis: nixfmt (via conform) handles
      # layout, nil/nixd handle semantics, and the two sources below own the
      # lint side:
      #
      #   - deadnix: unused let-bindings, unused lambda params, dead branches.
      #   - statix:  stylistic anti-patterns + redundancy lints. Wired both
      #              as a diagnostic source and as code_actions so the
      #              fixable ones (e.g. manual-inherit, redundant-pattern-bind)
      #              show up under `<leader>ca`.
      #
      # We intentionally do not register any formatter sources here — conform
      # is the single formatter dispatcher, and none-ls's lsp-format auto-wire
      # would otherwise race with it.
      plugins.none-ls = {
        enable = _ true;
        enableLspFormat = _ false;
        sources = {
          diagnostics = {
            deadnix.enable = _ true;
            statix.enable = _ true;
          };
          code_actions = {
            statix.enable = _ true;
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
