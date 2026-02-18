# --- flake-parts/modules/home-manager/programs/dsearch.nix
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
{ localFlake, inputs }:
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.dsearch;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.dsearch = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  imports = [
    inputs.danksearch.homeModules.default
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.dsearch = {
        enable = _ true;
        config = {
          # index_path = "~/.cache/danksearch/index";
          # max_file_bytes = 2097152; # 2MB
          worker_count = _ 4;
          index_all_files = _ true;
          auto_reindex = _ true;
          reindex_interval_hours = _ 24;

          text_extensions = [
            ".txt"
            ".md"
            ".go"
            ".py"
            ".js"
            ".ts"
            ".jsx"
            ".tsx"
            ".json"
            ".yaml"
            ".yml"
            ".toml"
            ".html"
            ".css"
            ".rs"
          ];

          index_paths = [
            {
              path = config.home.sessionVariables.PROJECTS_DIR;
              max_depth = 6;
              exclude_hidden = true;
              exclude_dirs = [
                ".git"
                "target"
                "dist"
                "node_modules"
                ".direnv"
                ".devenv"
                "venv"
                "target"
              ];
            }
            {
              path = config.home.sessionVariables.DOWNLOADS_DIR;
              max_depth = 3;
              exclude_hidden = true;
              exclude_dirs = [
                ".git"
                "target"
                "dist"
                "node_modules"
                ".direnv"
                ".devenv"
                "venv"
                "target"
              ];
            }
            {
              path = config.home.sessionVariables.MISC_DATA_DIR;
              max_depth = 6;
              exclude_hidden = true;
              exclude_dirs = [
                "node_modules"
                ".git"
                "target"
                "dist"
              ];
            }
          ];
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
