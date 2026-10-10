# --- flake-parts/modules/home-manager/programs/evnia-panel.nix
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
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    literalExpression
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.evnia-panel;
  _ = mkOverrideAtHmModuleLevel;

  niriCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.niri-flake";
in
{
  options.tensorfiles.hm.programs.evnia-panel = {
    enable = mkEnableOption ''
      Installs `evnia-panel`, a keybind-summoned overlay panel (GTK4 +
      layer-shell) and CLI for the Philips Evnia 32M2N8900P: picture mode,
      picture settings, Ambiglow, pixel orbiting, input and audio over DDC/CI
      plus the USB LampArray. See `flake-parts/pkgs/evnia-panel/README.md`.

      Host side: `/dev/i2c-*` needs `hardware.i2c.enable` (part of the
      `graphical-dms-niri` profile) and the Ambiglow hidraw node needs the
      udev rule the package ships -- add
      `services.udev.packages = [ <the evnia-panel package> ];` to the host.
    '';

    package = mkOption {
      type = types.package;
      default = localFlake.packages.${system}.evnia-panel;
      defaultText = literalExpression "tensorfiles.packages.\${system}.evnia-panel";
      description = "The `evnia-panel` package, see `flake-parts/pkgs/evnia-panel`.";
    };

    modes = mkOption {
      type = types.attrsOf types.str;
      default = {
        "00" = "Standard";
        "01" = "FPS?";
        "03" = "Movie?";
        "04" = "Game1";
        "05" = "05?";
        "06" = "06?";
        "07" = "07?";
        "08" = "Economy";
        "0B" = "LowBlueMode?";
        "0E" = "EasyRead";
        "51" = "Illustrator?";
      };
      example = literalExpression ''
        {
          "00" = "Standard";
          "08" = "Economy";
          "0E" = "EasyRead";
        }
      '';
      description = ''
        Picture mode map shown by the panel: VCP `DC` value (hex, two
        digits) to label. Written to `$XDG_CONFIG_HOME/evnia-panel/modes.json`.
        Labels ending in `?` are the research notes' unconfirmed guesses;
        `05`/`06`/`07` are Racing/RTS/Game2 in an unknown order. Values the
        monitor reports outside this map show as their hex.
      '';
    };

    bind = mkOption {
      type = types.str;
      default = "Mod+Shift+M";
      description = ''
        niri keybind that runs `evnia-panel-toggle` (open / close). Only
        installed when `tensorfiles.hm.programs.niri-flake` is enabled.
      '';
    };

    daemon = {
      enable =
        mkEnableOption ''
          a resident `evnia-panel --daemon` user service: the panel is built
          once at login and only shown/hidden on each summon, so a toggle
          costs one DBus round trip instead of the ~500 ms Python + GTK cold
          start. `evnia-panel-toggle` falls back to a plain launch when the
          service is not running.
        ''
        // {
          default = true;
        };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = [ cfg.package ];

      xdg.configFile."evnia-panel/modes.json".text = _ (builtins.toJSON cfg.modes);
    }
    # |----------------------------------------------------------------------| #
    (mkIf niriCheck {
      programs.niri.settings.binds."${cfg.bind}".action = _ (
        config.lib.niri.actions.spawn [ "evnia-panel-toggle" ]
      );
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.daemon.enable {
      systemd.user.services.evnia-panel = {
        Unit = {
          Description = _ "Resident Evnia monitor control panel";
          PartOf = _ [ "graphical-session.target" ];
          After = _ [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = _ "${lib.getExe cfg.package} --daemon";
          Restart = _ "on-failure";
          RestartSec = _ 2;
        };
        Install.WantedBy = _ [ "graphical-session.target" ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
