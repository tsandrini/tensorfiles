# --- flake-parts/modules/home-manager/programs/tmux.nix
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
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.tmux;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.tmux = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.tmux = {
        enable = _ true;
        clock24 = _ true;
        keyMode = _ "vi";
        aggressiveResize = _ true;
        mouse = _ true;
        prefix = _ "C-a";
        extraConfig = ''
          set -g default-terminal "$TERM"
          setenv -g COLORTERM "truecolor"

          set -s escape-time 0

          # fix SSH agent after reconnecting
          # see also ssh/rc
          # https://blog.testdouble.com/posts/2016-11-18-reconciling-tmux-and-ssh-agent-forwarding/
          set -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
          setenv -g SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock

          # Ensure window index numbers get reordered on delete.
          set-option -g renumber-windows on

          # set terminal title
          set-option -g set-titles on
          set-option -g set-titles-string "#S / #W"

          # open splits and windows in the current folder
          bind v split-window -l 50% -h -c "#{pane_current_path}"
          bind s split-window -l 50% -v -c "#{pane_current_path}"
          bind n new-window -c "#{pane_current_path}"
          bind J prev
          bind K next

          # auto rename tmux window to current cwd
          set-option -g status-interval 1
          set-option -g automatic-rename on
          set-option -g automatic-rename-format '#{b:pane_current_path}'

          # blinking cursor
          set-option -g cursor-style blinking-block

          set -g status "on"
          set -g status-justify "left"
          set -g status-left-length "100"
          set -g status-right-length "100"
          set -g status-left ""

          if-shell -b 'test $(uname -s) = "Linux"' {
            set -g status-right "   #(hostname) "
          }

          if-shell -b 'test $(uname -s) = "Darwin"' {
            set -g status-right "   #(hostname | cut -f1 -d'.') "
          }
          set -g set-clipboard on
        '';
        plugins = with pkgs.tmuxPlugins; [
          sensible
          yank
          pain-control
          {
            plugin = resurrect;
            extraConfig = "set -g @resurrect-strategy-nvim 'session'";
          }
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '10' # minutes
            '';
          }
        ];
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
