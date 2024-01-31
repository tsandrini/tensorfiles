# --- parts/modules/home-manager/programs/pywal.nix
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
  config,
  lib,
  pkgs,
  self,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.pywal;

  impermanenceCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence =
    if impermanenceCheck
    then config.tensorfiles.hm.system.impermanence
    else {};
  pathToRelative = strings.removePrefix "${config.home.homeDirectory}/";

  plasmaCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.profiles.graphical-plasma";
  kdewallpaperset = pkgs.writeShellScriptBin "kdewallpaperset" ''
    #!/usr/bin/env bash

    full_image_path=$(realpath "$1")
    ext=$(${lib.getExe pkgs.file} -b --mime-type "$full_image_path")

    if [ -z "$2" ]; then
        # Identify filetype and make changes
        case $(echo $ext | cut -d'/' -f2) in
            "mp4"|"webm") type='VideoWallpaper' ; write='VideoWallpaperBackgroundVideo';;
            "png"|"jpeg") type='org.kde.image' ; write='Image' ;;
            "gif"|"webp") type='GifWallpaper' ; write="GifWallpaperBackgroundGif" ;;
        esac
    else
        type="$2";
        write="$3";
    fi

    wallpaper_set_script="var allDesktops = desktops();
        print (allDesktops);
        for (i=0;i<allDesktops.length;i++)
        {
            d = allDesktops[i];
            d.wallpaperPlugin = \"''${type}\";
            d.currentConfigGroup = Array('Wallpaper', \"''${type}\", 'General');
            d.writeConfig('Image', 'file:///dev/null')
            d.writeConfig('$write', 'file://''${full_image_path}')
        }"

    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "''${wallpaper_set_script}"

    # Optional, change lockscreen if you want
    kwriteconfig5 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$full_image_path"
  '';
  kdegencolorscheme = pkgs.writeShellScriptBin "kdegencolorscheme" ''
    #!/usr/bin/env bash
    #move pywal generated colors to a kde colorscheme, names the color scheme after the first given argument
    #to be run after pywal

    background=$(grep -A 1 Background] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    foreground=$(grep -A 1 Foreground] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)

    color0=$(grep -A 1 Color0Intense] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color1=$(grep -A 1 Color1] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color2=$(grep -A 1 Color2] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color3=$(grep -A 1 Color3] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color4=$(grep -A 1 Color4] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color5=$(grep -A 1 Color5] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color6=$(grep -A 1 Color6] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)
    color7=$(grep -A 1 Color7] ~/.cache/wal/colors-konsole.colorscheme | sed -r 's#.*=##' | tail -n 1)

    name=$1 #take input for a name to be used for the colorscheme
    echo "
    [ColorEffects:Disabled]
    Color=$background
    ColorAmount=0
    ColorEffect=3
    ContrastAmount=0.55
    ContrastEffect=1
    IntensityAmount=-1
    IntensityEffect=0

    [ColorEffects:Inactive]
    ChangeSelectionColor=true
    Color=$background
    ColorAmount=0
    ColorEffect=0
    ContrastAmount=0
    ContrastEffect=0
    Enable=false
    IntensityAmount=-1
    IntensityEffect=0

    [Colors:Button]
    BackgroundAlternate=$color0
    BackgroundNormal=$background
    DecorationFocus=$color3
    DecorationHover=$color3
    ForegroundActive=$color3
    ForegroundInactive=$color0
    ForegroundLink=$color3
    ForegroundNegative=$color2
    ForegroundNeutral=$color6
    ForegroundNormal=$foreground
    ForegroundPositive=$color5
    ForegroundVisited=$color0

    [Colors:Selection]
    BackgroundAlternate=$color3
    BackgroundNormal=$color3
    DecorationFocus=$color3
    DecorationHover=$color3
    ForegroundActive=$background
    ForegroundInactive=$color0
    ForegroundLink=$color3
    ForegroundNegative=$color2
    ForegroundNeutral=$color6
    ForegroundNormal=$foreground
    ForegroundPositive=$color5
    ForegroundVisited=$color0

    [Colors:Tooltip]
    BackgroundAlternate=$color0
    BackgroundNormal=$background
    DecorationFocus=$color3
    DecorationHover=$color3
    ForegroundActive=$color3
    ForegroundInactive=$color0
    ForegroundLink=$color3
    ForegroundNegative=$color2
    ForegroundNeutral=$color6
    ForegroundNormal=$foreground
    ForegroundPositive=$color5
    ForegroundVisited=$color0

    [Colors:View]
    BackgroundAlternate=$background
    BackgroundNormal=$background
    DecorationFocus=$color3
    DecorationHover=$color3
    ForegroundActive=$color3
    ForegroundInactive=$color0
    ForegroundLink=$color3
    ForegroundNegative=$color2
    ForegroundNeutral=$color6
    ForegroundNormal=$foreground
    ForegroundPositive=$color5
    ForegroundVisited=$color0

    [Colors:Window]
    BackgroundAlternate=$color0
    BackgroundNormal=$background
    DecorationFocus=$color3
    DecorationHover=$color3
    ForegroundActive=$color3
    ForegroundInactive=$color0
    ForegroundLink=$color3
    ForegroundNegative=$color2
    ForegroundNeutral=$color6
    ForegroundNormal=$foreground
    ForegroundPositive=$color5
    ForegroundVisited=$color0

    [General]
    ColorScheme=$1
    Name=$1
    shadeSortColumn=true

    [KDE]
    contrast=5

    [WM]
    activeBackground=$color3
    activeBlend=$color3
    activeForeground=$foreground
    inactiveBackground=$color0
    inactiveBlend=$color0
    inactiveForeground=$color7" > ~/.local/share/color-schemes/pywal-$1.colors
    kwriteconfig5 --file ~/.config/kdeglobals --group WM --key frame $color3 #these lines come from https://github.com/gikari/bismuth/blob/master/TWEAKS.md
    kwriteconfig5 --file ~/.config/kdeglobals --group WM --key inactiveFrame $color0 #they are used to change the color of the border around windows, useful if you use borders
  '';

  wal-switch = pkgs.writeShellScriptBin "wal-switch" ''
    #!/usr/bin/env bash
    wal -i $1

    ${
      if (isModuleLoadedAndEnabled config "tensorfiles.hm.services.pywalfox-native")
      then ''
        echo "Changing firefox theme to pywalfox-native..."
        pywalfox update
      ''
      else ""
    }
    ${
      if (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.editors.emacs-doom")
      then ''
        echo "Changing emacs theme to ewal-doom-one..."
        emacsclient -e "(progn (load-theme 'ewal-doom-one))"
      ''
      else ""
    }
    ${
      if plasmaCheck
      then ''
        echo "Changing KDE wallpaper ...."
        ${kdewallpaperset}/bin/kdewallpaperset $1
        echo "Changing KDE color scheme ...."
        # In case it doesnt exist
        mkdir -p ~/.local/share/color-schemes
        rm ~/.local/share/color-schemes/pywal*
        ${kdegencolorscheme}/bin/kdegencolorscheme $(basename $1 | cut -d. -f1)
        plasma-apply-colorscheme "pywal-$(basename $1 | cut -d. -f1)"
      ''
      else ""
    }
  '';
in {
  options.tensorfiles.hm.programs.pywal = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles pywal colorscheme generator.
    '');

    impermanence = {enable = mkImpermanenceEnableOption;};

    pkg = mkOption {
      type = package;
      default = pkgs.pywal;
      description = mdDoc ''
        Which package to use for the pywal utilities. You can provide any
        custom derivation or forks with differing internals as long
        as the API and binaries stay the same and reside at the
        same place.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages =
        [cfg.pkg]
        ++ (
          if plasmaCheck
          then [wal-switch kdewallpaperset kdegencolorscheme]
          else []
        );

      # TODO add a conditional for Xorg vs Wayland
      systemd.user.tmpfiles.rules = ["L ${config.home.homeDirectory}/.Xresources - - - - ${config.xdg.cacheHome}/wal/Xresources"];
      xdg.configFile."wal/templates/Xresources".text = mkBefore ''
        ! Xft.autohint: 0
        ! Xft*antialias: true
        ! Xft.hinting: true
        ! Xft.hintstyle: hintslight
        ! Xft*dpi: 96
        ! Xft.lcdfilter: lcddefault

        *.background: {background}
        *.foreground: {foreground}
        *.cursorColor: {cursor}

        ! Colors 0-15.
        *.color0: {color0}
        *color0:  {color0}
        *.color1: {color1}
        *color1:  {color1}
        *.color2: {color2}
        *color2:  {color2}
        *.color3: {color3}
        *color3:  {color3}
        *.color4: {color4}
        *color4:  {color4}
        *.color5: {color5}
        *color5:  {color5}
        *.color6: {color6}
        *color6:  {color6}
        *.color7: {color7}
        *color7:  {color7}
        *.color8: {color8}
        *color8:  {color8}
        *.color9: {color9}
        *color9:  {color9}
        *.color10: {color10}
        *color10:  {color10}
        *.color11: {color11}
        *color11:  {color11}
        *.color12: {color12}
        *color12:  {color12}
        *.color13: {color13}
        *color13:  {color13}
        *.color14: {color14}
        *color14:  {color14}
        *.color15: {color15}
        *color15:  {color15}
      '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        directories = [
          (pathToRelative "${config.xdg.cacheHome}/wal")
        ];
        files = [".fehbg"];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);
}
