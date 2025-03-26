# --- flake-parts/modules/nixvim/plugins/lsp/fidget.nix
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
{ localFlake }:
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.lsp.fidget;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.lsp.fidget = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      plugins.fidget = {
        enable = _ true;
        settings = {
          logger = {
            level = _ "warn"; # “off”, “error”, “warn”, “info”, “debug”, “trace”
            float_precision = _ 1.0e-2; # Limit the number of decimals displayed for floats
          };
          progress = {
            poll_rate = _ 0; # How and when to poll for progress messages
            # suppressOnInsert = true; # Suppress new messages while in insert mode
            ignore_done_already = _ false; # Ignore new tasks that are already complete
            ignore_empty_message = _ false; # Ignore new tasks that don't contain a message
            clear_on_detach =
              # Clear notification group when LSP server detaches
              lib.nixvim.mkRaw ''
                function(client_id)
                  local client = vim.lsp.get_client_by_id(client_id)
                  return client and client.name or nil
                end
              '';
            notification_group =
              # How to get a progress message's notification group key
              lib.nixvim.mkRaw ''
                function(msg) return msg.lsp_client.name end
              '';
            ignore = [ ]; # List of LSP servers to ignore
            lsp = {
              progress_ringbuf_size = _ 0; # Configure the nvim's LSP progress ring buffer size
            };
            display = {
              render_limit = _ 16; # How many LSP messages to show at once
              done_ttl = _ 3; # How long a message should persist after completion
              done_icon = _ "✔"; # Icon shown when all LSP progress tasks are complete
              done_style = _ "Constant"; # Highlight group for completed LSP tasks
              progress_ttl = lib.nixvim.mkRaw "math.huge"; # How long a message should persist when in progress
              progress_icon = {
                pattern = _ "dots";
                period = _ 1;
              }; # Icon shown when LSP progress tasks are in progress
              progress_style = _ "WarningMsg"; # Highlight group for in-progress LSP tasks
              group_style = _ "Title"; # Highlight group for group name (LSP server name)
              icon_style = _ "Question"; # Highlight group for group icons
              priority = _ 30; # Ordering priority for LSP notification group
              skip_history = _ true; # Whether progress notifications should be omitted from history
              format_message = lib.nixvim.mkRaw ''
                require ("fidget.progress.display").default_format_message
              ''; # How to format a progress message
              format_annote = lib.nixvim.mkRaw ''
                function(msg) return msg.title end
              ''; # How to format a progress annotation
              format_group_name = lib.nixvim.mkRaw ''
                function(group) return tostring (group) end
              ''; # How to format a progress notification group's name
              overrides = {
                rust_analyzer = {
                  name = _ "rust-analyzer";
                };
              }; # Override options from the default notification config
            };
          };
          notification = {
            poll_rate = _ 10; # How frequently to update and render notifications
            filter = _ "info"; # “off”, “error”, “warn”, “info”, “debug”, “trace”
            history_size = _ 128; # Number of removed messages to retain in history
            override_vim_notify = _ true;
            redirect = lib.nixvim.mkRaw ''
              function(msg, level, opts)
                if opts and opts.on_open then
                  return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
                end
              end
            '';
            configs = {
              default = lib.nixvim.mkRaw "require('fidget.notification').default_config";
            };

            window = {
              normal_hl = _ "Comment";
              winblend = _ 0;
              border = _ "none"; # none, single, double, rounded, solid, shadow
              zindex = _ 45;
              max_width = _ 0;
              max_height = _ 0;
              x_padding = _ 1;
              y_padding = _ 0;
              align = _ "bottom";
              relative = _ "editor";
            };
            view = {
              stack_upwards = _ true; # Display notification items from bottom to top
              icon_separator = _ " "; # Separator between group name and icon
              group_separator = _ "---"; # Separator between notification groups
              group_separator_hl =
                # Highlight group used for group separator
                "Comment";
            };
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
