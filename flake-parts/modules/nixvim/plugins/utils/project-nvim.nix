# --- flake-parts/modules/nixvim/plugins/utils/project-nvim.nix
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
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.nixvim.plugins.utils.project-nvim;
  _ = mkOverrideAtNixvimModuleLevel;

  telescopeCheck = isModuleLoadedAndEnabled config "tensorfiles.nixvim.plugins.utils.telescope";
in
{
  options.tensorfiles.nixvim.plugins.utils.project-nvim = {
    enable = mkEnableOption ''
      TODO
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
      # NOTE: Monkey-patch project.nvim's history read/write to handle
      # concurrent nvim instances. The upstream plugin has no file locking,
      # so simultaneous writes corrupt the JSON history file.
      #
      # Three problems fixed here:
      # 1. write_history reads the file then writes — races with other instances
      # 2. The fs_event watcher fires read_history in a libuv fast-event
      #    context, where vim.fn.* / vim.notify (via fidget.nvim) cannot run
      # 3. read_history calls write_history when the file is empty (mid-truncate
      #    by another instance), cascading the failure
      #
      # The fix: wrap both read and write in pcall, defer all vim.fn/notify
      # calls via vim.schedule, and use atomic write-to-temp + rename.
      extraConfigLuaPost = ''
        do
          local ok_hist, History = pcall(require, 'project.util.history')
          if not (ok_hist and History) then return end

          local Path = require('project.util.path')
          local uv = vim.uv or vim.loop

          -- Safe notify that works even inside libuv fast-event callbacks
          local function safe_notify(msg, level)
            vim.schedule(function()
              vim.notify(msg, level)
            end)
          end

          -- Atomic write: write to a temp file then rename, so readers
          -- never see a half-written file.
          local function atomic_write_json(filepath, data)
            local tmp = filepath .. '.tmp.' .. uv.getpid()
            local fd = uv.fs_open(tmp, 'w', 438) -- 0666
            if not fd then return false end
            local ok_enc, json = pcall(vim.json.encode, data)
            if not (ok_enc and json) then
              uv.fs_close(fd)
              uv.fs_unlink(tmp)
              return false
            end
            uv.fs_write(fd, json)
            uv.fs_close(fd)
            local ok_rename = uv.fs_rename(tmp, filepath)
            if not ok_rename then
              uv.fs_unlink(tmp)
              return false
            end
            return true
          end

          -- Safe JSON read: returns decoded table or nil
          local function safe_read_json(filepath)
            local fd, stat
            if filepath == Path.historyfile then
              fd, stat = History.open_history('r')
            else
              fd, stat = Path.open_file(filepath, 'r')
            end
            if not (fd and stat) then
              if fd then uv.fs_close(fd) end
              return nil
            end
            if stat.size == 0 then
              uv.fs_close(fd)
              return {}
            end
            local raw = uv.fs_read(fd, stat.size)
            uv.fs_close(fd)
            if not raw then return nil end
            local ok_dec, data = pcall(vim.json.decode, raw)
            if ok_dec and type(data) == 'table' then
              return data
            end
            return nil
          end

          if History.write_history then
            local orig_write = History.write_history
            History.write_history = function(path, ...)
              -- Try the original first
              local ok_w, err = pcall(orig_write, path, ...)
              if not ok_w then
                -- Original failed (likely corrupt JSON during read-back),
                -- attempt an atomic write with just our session projects
                safe_notify(
                  '[project.nvim] History write failed, attempting atomic recovery.',
                  vim.log.levels.WARN
                )
                local target = path or Path.historyfile
                if not target then return end
                -- Collect what we can from memory
                local projects = {}
                if History.recent_projects then
                  vim.list_extend(projects, History.recent_projects)
                end
                if History.session_projects then
                  vim.list_extend(projects, History.session_projects)
                end
                if #projects > 0 then
                  atomic_write_json(target, projects)
                else
                  atomic_write_json(target, {})
                end
              end
            end
          end

          if History.read_history then
            local orig_read = History.read_history
            History.read_history = function(...)
              local ok_r, err = pcall(orig_read, ...)
              if not ok_r then
                safe_notify(
                  '[project.nvim] History read failed, file may be temporarily corrupt.',
                  vim.log.levels.WARN
                )
              end
            end
          end
        end
      '';

      # NOTE: This fixes a check build time issue where project-nvim
      # tries to search for history inside $HOME (which doesn't work inside a sandbox)
      plugins.project-nvim = {
        enable = _ true;
        enableTelescope = _ telescopeCheck;
        # NOTE DEFAULT produces too many false positives
        # settings.patterns = [ ".git" "_darcs" ".hg" ".bzr" ".svn" "Makefile" "package.json" ];
        settings = {
          disable_on = {
            ft = [
              "NvimTree"
              "TelescopePrompt"
              "TelescopeResults"
              "alpha"
              "checkhealth"
              "lazy"
              "log"
              "ministarter"
              "neo-tree"
              "notify"
              "nvim-pack"
              "packer"
              "qf"
            ];
            bt = [
              "help"
              "nofile"
              "nowrite"
              "terminal"
            ];
          };

          patterns = [
            ".git"
            ".projectfile"
          ];
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.withKeymaps && telescopeCheck) {
      keymaps = [
        {
          mode = "n";
          key = "<leader>pp";
          action = "<cmd>Telescope projects<CR>";
          options = {
            desc = "Telescope projects.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
