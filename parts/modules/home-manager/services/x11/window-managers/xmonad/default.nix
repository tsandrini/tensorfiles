# --- parts/modules/home-manager/services/x11/window-managers/xmonad/default.nix
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

  cfg = config.tensorfiles.hm.services.x11.window-managers.xmonad;
  _ = mkOverride 700;

  pywalCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable;
  dmenuCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.dmenu";

  trayer-padding-icon = pkgs.writeShellScriptBin "trayer-padding-icon" ''
    #!/bin/sh
    # Copied from https://github.com/jaor/xmobar/issues/239#issuecomment-233206552
    # Detects the width of running trayer-srg window (xprop name 'panel')
    # and creates an XPM icon of that width, 1px height, and transparent.
    # Outputs an <icon>-tag for use in xmobar to display the generated
    # XPM icon.
    #
    # Run script from xmobar:
    # `Run Com "/where/ever/trayer-padding-icon.sh" [] "trayerpad" 10`
    # and use `%trayerpad%` in your template.

    # Function to create a transparent Wx1 px XPM icon
    create_xpm_icon () {
        timestamp=$(date)
        pixels=$(for i in `seq $1`; do echo -n "."; done)

        cat << EOF > "$2"
    /* XPM *
    static char * trayer_pad_xpm[] = {
    /* This XPM icon is used for padding in xmobar to */
    /* leave room for trayer-srg. It is dynamically   */
    /* updated by by trayer-padding-icon.sh which is run  */
    /* by xmobar.                                     */
    /* Created: ''${timestamp} */
    /* <w/cols>  <h/rows>  <colors>  <chars per pixel> */
    "$1 1 1 1",
    /* Colors (none: transparent) */
    ". c none",
    /* Pixels */
    "$pixels"
    };
    EOF
    }

    # Width of the trayer window
    width=$(xprop -name panel | grep 'program specified minimum size' | cut -d ' ' -f 5)

    # Icon file name
    iconfile="/tmp/trayer-padding-''${width}px.xpm"

    # If the desired icon does not exist create it
    if [ ! -f $iconfile ]; then
        create_xpm_icon $width $iconfile
    fi

    # Output the icon tag for xmobar
    echo "<icon=''${iconfile}/>"
  '';
in {
  options.tensorfiles.hm.services.x11.window-managers.xmonad = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the xmonad window manager.
    '');

    pywal = {enable = mkPywalEnableOption;};

    cbatticon = {
      enable =
        mkEnableOption (mdDoc ''
          Enable the cbatticon battery indicator.
          Doing so install the appropriate derivation and adds the
          management code into the xmonad configuration.

          https://github.com/valr/cbatticon
        '')
        // {default = true;};

      pkg = mkOption {
        type = package;
        default = pkgs.cbatticon;
        description = mdDoc ''
          Which package to use for the battery indicator.
          You can provide any custom derivation as long as the main binary
          resides at `$pkg/bin/cbatticon`.
        '';
      };
    };

    playerctl = {
      enable =
        mkEnableOption (mdDoc ''
          Enable integration with the playerctl toolset. Doing so enables the
          media keys functionality.

          https://github.com/altdesktop/playerctl
        '')
        // {default = true;};

      pkg = mkOption {
        type = package;
        default = pkgs.playerctl;
        description = mdDoc ''
          Which package to use for the playerctl utility.
          You can provide any custom derivation as long as the main binary
          resides at `$pkg/bin/playerctl`.
        '';
      };
    };

    dmenu = {
      enable =
        mkEnableOption (mdDoc ''
          Enable the dmenu app launcher integration.
          This does **one of** two things, first off

          1. If `tensorfiles.programs.dmenu` is installed and enabled it will
             use whatever is defined inside that module.

          2. If not, it will install `dmenu.pkg` and use that version.

          and secondly, it creates the keyboard mappings.
        '')
        // {default = true;};

      pkg = mkOption {
        type = package;
        default = pkgs.dmenu;
        description = mdDoc ''
          Which package to use for the dmenu app launcher.
          You can provide any custom derivation as long as the main binary
          resides at `$pkg/bin/dmenu`, `$pkg/bin/dmenu_run`, ..
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home = {
        packages = with pkgs;
          [
            trayer-padding-icon
            haskellPackages.xmobar
            i3lock-fancy-rapid
            ubuntu_font_family
            (nerdfonts.override {fonts = ["Ubuntu" "UbuntuMono"];})
            ubuntu_font_family
            feh
            trayer
            xfce.xfce4-clipman-plugin
            light
          ]
          ++ (
            if cfg.dmenu.enable
            then
              (
                if dmenuCheck
                then []
                else cfg.dmenu.pkg
              )
            else []
          )
          ++ (optional cfg.cbatticon.enable cfg.cbatticon.pkg)
          ++ (optional cfg.playerctl.enable cfg.playerctl.pkg);

        # lil haskell icon ^^
        file."${config.home.homeDirectory}/.xmonad/xpm/haskell_20.xpm".source =
          _ ./xpm/haskell_20.xpm;

        file."${config.xdg.configHome}/wal/templates/xmobarrc".text = ''
          Config {{

                 -- ~Appearance~
                   font    = "xft:Ubuntu:weight=bold:pixelsize=11:antialias=true:hinting=true"
                 , additionalFonts = [ "xft:Ubuntu Nerd Font Mono:pixelsize=13:antialias=true:hinting=true" ]
                 , alpha = 200 -- alpha in [0,255]
                 , bgColor = "{background}"
                 , fgColor = "{foreground}"
                 , position = TopSize L 100 22,
                 , iconRoot = "${config.home.homeDirectory}/.xmonad/xpm"

                 -- ~Layout~
                 , sepChar = "%"
                 , alignSep = "}}{{"
                 , template = " <icon=haskell_20.xpm/> <fc={color14}>|</fc> %UnsafeStdinReader% }}{{  <fc={color14}>|</fc> <fc={color1}>%uname%</fc> <fc={color14}>|</fc> %cpu% <fc={color14}>|</fc> %coretemp% <fc={color14}>|</fc> %memory% <fc={color14}>|</fc> %dynnetwork% <fc={color14}>|</fc> %disku% <fc={color14}>|</fc> %battery% <fc={color14}>|</fc> %date% <fc={color14}><fn=1>|</fn></fc> %trayerpad%"

                 -- ~Behaviour~
                 , lowerOnStart = True
                 , hideOnStart = False
                 , allDesktops = True
                 , overrideRedirect = True    -- set the Override Redirect flag (Xlib)
                 , persistent = True

                 , commands = [
                                Run Com "uname" ["-r", "-m"] "" 10000
                                , Run DynNetwork
                                ["-t"          , " <fc={foreground}><fn=1>\xf09e</fn></fc> <fc={color10}><dev></fc> <fc={color14}>|</fc> <fc={foreground}><fn=1>\xf0aa</fn></fc> <fc={color5}><rx>kB/s</fc> <fc={foreground}><fn=1>\xf0ab</fn></fc> <fc={color5}><tx>kB/s</fc> "
                                , "--High"     , "5000"       -- units: B/s
                                , "--high"     , "darkred"
                                ] 20
                                , Run Cpu
                                [ "-t"         , " <fc={foreground}><fn=1>\xe266</fn></fc> <fc={color10}><total>%</fc> "
                                , "--High"     , "85"         -- units: %
                                , "--high"     , "darkred"
                                ] 20
                                , Run CoreTemp
                                [ "-t"         , " <fc={foreground}><fn=1>\xf8c7</fn></fc> <fc={color5}><core0>°C</fc> "
                                , "--High"     , "80"        -- units: °C
                                , "--high"     , "darkred"
                                ] 50
                                , Run Memory
                                [ "-t"         ," <fc={foreground}><fn=1>\xf85a</fn></fc> <fc={color1}><usedratio>%</fc>"
                                , "--High"     , "90"        -- units: %
                                , "--high"     , "darkred"
                                ] 20
                                , Run DiskU
                                [ ("/"         , " <fc={foreground}><fn=1>\xe706</fn></fc> <fc={color1}><used>/<size> (<usedp>%)</fc> ")]
                                [ "--High"     , "50"        -- units: %
                                , "--high"     , "darkred"
                                ] 200
                                , Run Battery
                                [ "--template" , " <acstatus> <fc={color10}><left>% (<timeleft>)</fc> "
                                , "--Low"      , "20"        -- units: %
                                , "--low"      , "darkred"
                                , "--" -- battery specific options
                                , "-o"	, "<fc={foreground}><fn=1>\xf57e</fn></fc>"  -- discharging
                                , "-O"	, "<fc={foreground}><fn=1>\xf583</fn></fc>" -- charging
                                , "-i"	, "<fc={foreground}><fn=1>\xf58e</fn></fc>" -- charged
                                ] 100
                                , Run Date "<fn=1>\xf017</fn>  <fc={color5}>%b %d %Y - (%H:%M)</fc> " "date" 50
                                -- Script that dynamically adjusts xmobar padding depending on number of trayer icons.
                                , Run Com "trayer-padding-icon" [] "trayerpad" 20
                                -- Prints out the left side items such as workspaces, layout, etc.
                                , Run UnsafeStdinReader
                              ]
                 }}
        '';
      };

      systemd.user.tmpfiles.rules = [
        "L ${config.xdg.configHome}/xmobar/xmobarrc - - - - ${config.xdg.cacheHome}/wal/xmobarrc"
      ];

      services.flameshot = {
        enable = _ true;
        settings = {
          General.showStartupLaunchMessage = _ false;
        };
      };

      services.pasystray.enable = _ true;

      xsession = {
        enable = _ true;
        scriptPath = _ ".xinitrc";

        windowManager.command = mkOverride 50 "exec xmonad";
        windowManager.xmonad = {
          enable = _ true;
          enableContribAndExtras = _ true;
          config = _ (pkgs.writeText "xmonad.hs" ''
            import Control.Exception (try)
            import qualified Data.Map as M
            import Data.Maybe
              ( fromJust,
                fromMaybe,
              )
            import Data.Monoid
            import Graphics.X11.ExtraTypes.XorgDefault
            import System.Directory
            import System.Exit (exitSuccess)
            import System.IO (hPutStrLn)
            import XMonad
            import XMonad.Actions.CopyWindow (kill1)
            import XMonad.Actions.CycleWS (toggleWS)
            import XMonad.Actions.MouseResize
            import XMonad.Actions.WindowGo (runOrRaise)
            import XMonad.Hooks.DynamicLog
              ( PP (..),
                dynamicLogWithPP,
                shorten,
                wrap,
                xmobarColor,
                xmobarPP,
              )
            import XMonad.Hooks.EwmhDesktops
            import XMonad.Hooks.ManageDocks
              ( avoidStruts,
                manageDocks,
              )
            import XMonad.Hooks.ManageHelpers
              ( doFullFloat,
                isFullscreen,
              )
            import XMonad.Layout.GridVariants (Grid (Grid))
            import XMonad.Layout.IndependentScreens
            import XMonad.Layout.LayoutModifier
            import XMonad.Layout.LimitWindows (limitWindows)
            import XMonad.Layout.Magnifier
            import XMonad.Layout.MultiToggle
              ( EOT (EOT),
                mkToggle,
                single,
                (??),
              )
            import qualified XMonad.Layout.MultiToggle as MT
              ( Toggle (..),
              )
            import XMonad.Layout.MultiToggle.Instances
              ( StdTransformers
                  ( MIRROR,
                    NBFULL,
                    NOBORDERS
                  ),
              )
            import XMonad.Layout.NoBorders
            import XMonad.Layout.Renamed
            import XMonad.Layout.ResizableTile
            import XMonad.Layout.Simplest
            import XMonad.Layout.SimplestFloat
            import XMonad.Layout.Spacing
            import XMonad.Layout.Spiral (spiral)
            import XMonad.Layout.SubLayouts
            import XMonad.Layout.Tabbed
            import qualified XMonad.Layout.ToggleLayouts as T
              ( toggleLayouts,
              )
            import XMonad.Layout.WindowArranger (windowArrange)
            import XMonad.Util.EZConfig (additionalKeysP)
            import XMonad.Util.NamedScratchpad
            import XMonad.Util.Run (safeSpawn, spawnPipe)
            import XMonad.Util.SpawnOnce

            myModMask :: KeyMask
            myModMask = mod4Mask

            myTerminal :: String
            myTerminal = "${
              if config.home.sessionVariables.TERMINAL != null
              then config.home.sessionVariables.TERMINAL
              else "xterm"
            }"

            myFileManager :: String
            myFileManager = "lf"

            myBorderWidth :: Dimension
            myBorderWidth = 2

            myWorkspaces :: [String]
            myWorkspaces = map show [1 .. 9]

            mySpacing ::
              Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
            mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

            mySpacing' ::
              Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
            mySpacing' i = spacingRaw True (Border i i i i) True (Border i i i i) True

            getColors :: IO [String]
            ${
              if pywalCheck
              then ''
                getColors = do
                  contents <- readFile "${config.xdg.cacheHome}/wal/colors"
                  let colors = lines contents
                  return (colors ++ replicate (16 - length colors) "#000000")
              ''
              else ''
                getColors = do
                  return [
                    "#000000"
                    "#9AEDFE"
                    "#000000"
                    "#000000"
                    "#000000"
                    "#000000"
                    "#000000"
                    "#000000"
                    "#000000"
                    "#292d3e"
                    "#F07178"
                    "#000000"
                    "#c3e88d"
                    "#c3e88d"
                    "#82AAFF"
                    "#000000"
                  ]
              ''
            }

            tall =
              renamed [Replace "tall"] $
                smartBorders $
                  subLayout [] (smartBorders Simplest) $
                    limitWindows 30 $
                      mySpacing 25 $
                        ResizableTall 1 (3 / 100) (1 / 2) []

            grid =
              renamed [Replace "grid"] $
                smartBorders $
                  subLayout [] (smartBorders Simplest) $
                    limitWindows 30 $
                      mySpacing 25 $
                        mkToggle (single MIRROR) $
                          Grid (16 / 10)

            fib =
              renamed [Replace "spiral"] $
                smartBorders $
                  subLayout [] (smartBorders Simplest) $
                    limitWindows 30 $
                      mySpacing 25 $
                        spiral (6 / 7)

            magnifyLayout =
              renamed [Replace "magnify"] $
                smartBorders $
                  subLayout [] (smartBorders Simplest) $
                    magnifier $
                      limitWindows 30 $
                        mySpacing 25 $
                          ResizableTall 1 (3 / 100) (1 / 2) []

            floats =
              renamed [Replace "floats"] $ smartBorders $ limitWindows 20 simplestFloat

            myWorkspaceIndices :: M.Map String Integer
            myWorkspaceIndices = M.fromList $ zip myWorkspaces [1 ..] -- (,) == \x y -> (x,y)

            clickable :: [Char] -> [Char]
            clickable ws =
              "<action=xdotool key super+" ++ show i ++ ">" ++ ws ++ "</action>"
              where
                i = fromJust $ M.lookup ws myWorkspaceIndices

            myLayoutHook =
              avoidStruts $
                mouseResize $
                  windowArrange $
                    T.toggleLayouts floats $
                      mkToggle
                        (NBFULL ?? NOBORDERS ?? EOT)
                        myDefaultLayout
              where
                myDefaultLayout =
                  withBorder myBorderWidth tall ||| withBorder myBorderWidth grid ||| withBorder myBorderWidth fib ||| magnifyLayout

            myStartupHook :: [String] -> X ()
            myStartupHook colors = do
              -- X init
              ${
              if pywalCheck
              then ''
                spawnOnce "wal -R"
              ''
              else ""
            }
              -- Apps: base
              ${
              with cfg.cbatticon; (
                if enable
                then ''
                  spawn "pgrep cbatticon > /dev/null || ${pkg}/bin/cbatticon &"
                ''
                else ""
              )
            }
              spawnOnce "pgrep xfce4-clipman > /dev/null || xfce4-clipman &"

              -- Apps: these should restart every time
              -- spawn "(${pkgs.killall}/bin/killall -q dunst || true) && dunst &"
              spawn "systemctl --user restart dunst.service > /dev/null"

              spawn
                ( "(${pkgs.killall}/bin/killall -q trayer || true) && ${pkgs.trayer}/bin/trayer --edge top --align right --widthtype request --padding 6 \
                  \--SetDockType true --SetPartialStrut true --expand true --monitor 0 \
                  \--transparent true --alpha 80 --height 22 --tint x"
                    ++ tail (head colors)
                    ++ " &"
                )

            myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
            myManageHook =
              composeAll
                [ className =? "confirm" --> doFloat,
                  className =? "file_progress" --> doFloat,
                  className =? "dialog" --> doFloat,
                  className =? "download" --> doFloat,
                  className =? "error" --> doFloat,
                  className =? "Gimp" --> doFloat,
                  className =? "notification" --> doFloat,
                  className =? "pinentry-gtk-2" --> doFloat,
                  className =? "splash" --> doFloat,
                  className =? "toolbar" --> doFloat,
                  (className =? "firefox" <&&> resource =? "Dialog") --> doFloat, -- Float Firefox Dialog
                  isFullscreen --> doFullFloat
                ]

            myKeys :: [String] -> [(String, X ())]
            myKeys colors =
              [ -- Programs
                ("M-<Return>", spawn myTerminal),
                ${
              if cfg.dmenu.enable
              then ''
                ("M-d", spawn "dmenu_run -i -f -fn 'Ubuntu:pixelsize=11:antialias=true:hinting=true' -p 'Run: '"),
              ''
              else ""
            }
                -- TODO I give up, this just won't work how I want ...
                -- ("M-f", spawn myTerminal ++ " -e ." ++ myFileManager ++ ""),
                ("M-S-i", spawn "i3lock-fancy-rapid 5 'pixel'"),
                -- Kill windows
                ("M-S-q", kill1), -- Kill the currently focused client
                -- Workspaces
                ("M-<Tab>", toggleWS),
                -- Increase/decrease spacing (gaps)
                ("M-u", decWindowSpacing 4), -- Decrease window spacing
                ("M-i", incWindowSpacing 4), -- Increase window spacing
                -- Multimedia keys
                ("<XF86Mail>", runOrRaise "thunderbird" (resource =? "thunderbird")),
                ${
              with cfg.playerctl; (
                if enable
                then
                  (replaceStrings ["\n"] [""] ''
                    ("<XF86AudioPrev>", spawn "${pkg}/bin/playerctl previous"),
                    ("<XF86AudioNext>", spawn "${pkg}/bin/playerctl next"),
                    ("<XF86AudioPlay>", spawn "${pkg}/bin/playerctl play-pause"),
                    ("<XF86AudioStop>", spawn "${pkg}/bin/playerctl stop"),
                  '')
                else ""
              )
            }
                ("<XF86Display>", spawn "autorandr --cycle"),
                ("<XF86MonBrightnessUp>", spawn "light -A 5"),
                ("<XF86MonBrightnessDown>", spawn "light -U 5"),
                ("<Print>", spawn "flameshot gui")
              ]

            remap ::
              (KeySym -> KeySym) ->
              (XConfig l -> M.Map (KeyMask, KeySym) (X ())) ->
              (XConfig l -> M.Map (KeyMask, KeySym) (X ()))
            remap f keybinds = M.mapKeys (\(m, k) -> (m, f k)) . keybinds

            toCzech :: KeySym -> KeySym
            toCzech = \ks -> fromMaybe ks (M.lookup ks cz)
              where
                cz =
                  M.fromList $
                    zip
                      [xK_1 .. xK_9]
                      [ xK_plus,
                        xK_ecaron,
                        xK_scaron,
                        xK_ccaron,
                        xK_rcaron,
                        xK_zcaron,
                        xK_yacute,
                        xK_aacute,
                        xK_iacute
                      ]

            main :: IO ()
            main = do
              numScreens <- countScreens
              colors <- getColors
              xmprocs <- mapM (\i -> spawnPipe $ "xmobar ${config.xdg.configHome}/xmobar/xmobarrc -x " ++ show i) [0 .. numScreens - 1]
              xmonad $
                ewmh
                  def
                    { manageHook = myManageHook <+> manageDocks,
                      modMask = myModMask,
                      terminal = myTerminal,
                      startupHook = myStartupHook colors,
                      layoutHook = myLayoutHook,
                      borderWidth = myBorderWidth,
                      workspaces = myWorkspaces,
                      -- , keys               = remap toCzech (keys def)
                      keys = keys def,
                      normalBorderColor = colors !! 10,
                      focusedBorderColor = colors !! 12,
                      logHook =
                        mapM_
                          ( \handle ->
                              dynamicLogWithPP $
                                xmobarPP
                                  { ppOutput = hPutStrLn handle,
                                    ppCurrent = xmobarColor (colors !! 14) "" . wrap "[" "]",
                                    ppVisible = xmobarColor (colors !! 13) "" . clickable,
                                    ppHidden = xmobarColor (colors !! 15) "" . wrap "*" "" . clickable,
                                    ppHiddenNoWindows = xmobarColor (colors !! 11) "" . clickable,
                                    ppTitle = xmobarColor (colors !! 14) "" . shorten 60,
                                    ppSep = "<fc=" ++ (colors !! 2) ++ "> | </fc>",
                                    ppUrgent = xmobarColor (colors !! 15) "" . wrap "!" "!",
                                    -- , ppExtras = [windowCount],
                                    ppOrder = \(ws : l : t : ex) -> [ws, l] ++ ex ++ [t]
                                  }
                          )
                          xmprocs
                    }
                  `additionalKeysP` myKeys colors
          '');
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);
}
