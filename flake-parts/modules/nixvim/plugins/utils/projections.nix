# --- flake-parts/modules/nixvim/plugins/utils/projections.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.nixvim.plugins.utils.projections;
  _ = mkOverrideAtNixvimModuleLevel;

  telescopeCheck = isModuleLoadedAndEnabled config "tensorfiles.nixvim.plugins.utils.telescope";
in
{
  options.tensorfiles.nixvim.plugins.utils.projections = {
    enable = mkEnableOption ''
      Projections.nvim project and session manager. Concurrent-safe
      alternative to project.nvim using per-project session files.
    '';

    withKeymaps =
      mkEnableOption ''
        Enable the related included keymaps.
      ''
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      plugins.projections = {
        enable = _ true;
        settings = {
          patterns = [
            ".git"
            ".projectfile"
          ];
          # NOTE workspaces are registered dynamically in extraConfigLuaPost
          # below since ~/ProjectBundle has a two-level structure (org/repo)
          # and projections only scans direct children of a workspace.
          store_hooks = {
            pre = lib.nixvim.mkRaw ''
              function()
                -- Close neo-tree before storing session to avoid empty buffer issues
                if pcall(require, "neo-tree") then
                  vim.cmd([[Neotree action=close]])
                end
              end
            '';
          };
        };
      };

      extraConfigLuaPost = ''
        do
          local uv = vim.uv or vim.loop
          local Session = require("projections.session")
          local Workspace = require("projections.workspace")
          local patterns = { ".git", ".projectfile" }

          -- Check if a directory is a project (contains a pattern marker)
          local function is_project(dir)
            for _, pat in ipairs(patterns) do
              if uv.fs_stat(dir .. "/" .. pat) then return true end
            end
            return false
          end

          -- Auto-register parent of cwd as workspace if cwd is a project.
          -- Projections models projects as direct children of workspaces,
          -- so to register /a/b/myrepo we add /a/b as a workspace.
          local function auto_register_project()
            local cwd = uv.cwd()
            if cwd and is_project(cwd) then
              local parent = vim.fn.fnamemodify(cwd, ":h")
              if parent and parent ~= cwd then
                Workspace.add(parent, patterns)
              end
            end
          end

          -- Auto-register on enter and exit
          auto_register_project()
          vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
            callback = function()
              auto_register_project()
              Session.store(uv.cwd())
            end,
          })

          -- Switch to project if nvim was started in a project dir
          local switcher = require("projections.switcher")
          vim.api.nvim_create_autocmd({ "VimEnter" }, {
            callback = function()
              if vim.fn.argc() == 0 then
                switcher.switch(uv.cwd())
              end
            end,
          })

          -- Manual commands
          vim.api.nvim_create_user_command("AddWorkspace", function()
            Workspace.add(uv.cwd(), patterns)
          end, { desc = "Add cwd as a projections workspace" })

          vim.api.nvim_create_user_command("AddProject", function()
            auto_register_project()
            vim.notify("Registered project: " .. uv.cwd(), vim.log.levels.INFO)
          end, { desc = "Register current project (adds parent as workspace)" })

          vim.api.nvim_create_user_command("RemoveWorkspace", function(opts)
            local target = opts.args ~= "" and vim.fn.expand(opts.args) or uv.cwd()
            local cfg = require("projections.config")
            local path = cfg.workspaces_file
            if not path then return end
            local f = io.open(path, "r")
            if not f then return end
            local ok, data = pcall(vim.json.decode, f:read("*a"))
            f:close()
            if not (ok and data) then return end
            local filtered = vim.tbl_filter(function(ws)
              return vim.fn.resolve(ws.path) ~= vim.fn.resolve(target)
            end, data)
            f = io.open(path, "w")
            if f then
              f:write(vim.json.encode(filtered))
              f:close()
              vim.notify("Removed workspace: " .. target, vim.log.levels.INFO)
            end
          end, { nargs = "?", complete = "dir", desc = "Remove a workspace from projections" })

          vim.api.nvim_create_user_command("StoreProjectSession", function()
            Session.store(uv.cwd())
          end, { desc = "Store session for current project" })

          vim.api.nvim_create_user_command("RestoreProjectSession", function()
            Session.restore(uv.cwd())
          end, { desc = "Restore session for current project" })
        end
      '';

      opts.sessionoptions = _ "buffers,curdir,folds,globals,help,localoptions,tabpages,winsize";
    }
    # |----------------------------------------------------------------------| #
    (mkIf telescopeCheck {
      extraConfigLuaPost = ''
        require("telescope").load_extension("projections")
      '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.withKeymaps && telescopeCheck) {
      keymaps = [
        {
          mode = "n";
          key = "<leader>pp";
          action = "<cmd>Telescope projections<CR>";
          options = {
            desc = "Telescope projections.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
