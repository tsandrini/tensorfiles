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
myTerminal = "kitty"

myBrowser :: String
myBrowser = "firefox-developer-edition"

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

getConfigFilePath :: [Char] -> IO [Char]
getConfigFilePath f = getHomeDirectory >>= \hd -> return $ hd ++ "/" ++ f

getWalColors :: IO [String]
getWalColors = do
  file <- getConfigFilePath ".cache/wal/colors"
  contents <- readFile file
  let colors = lines contents
  return (colors ++ replicate (16 - length colors) "#000000")

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
  spawnOnce "wal -R"
  -- spawn "pgrep picom > /dev/null || picom &"
  -- Apps: base
  -- spawn "pgrep redshift-gtk > /dev/null || redshift-gtk &"
  spawn "pgrep keepassxc > /dev/null || keepassxc &"
  spawn "pgrep nm-applet > /dev/null || nm-applet &"
  -- spawn "pgrep volumeicon > /dev/null || volumeicon &"
  spawn "pgrep pasystray > /dev/null || pasystray &"
  spawn "pgrep cbatticon > /dev/null || cbatticon &" -- TODO remove
  spawn "pgrep xfce4-clipman > /dev/null || xfce4-clipman &"
  -- Apps: these should restart every time
  -- spawn "(killall -q dunst || true) && dunst &"
  spawn
    ( "(killall -q trayer || true) && trayer --edge top --align right --widthtype request --padding 6 \
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
    ( "M-d",
      spawn
        ( "dmenu_run -nb '" ++ head colors ++ "' -nf '"
            ++ (colors !! 15)
            ++ "' -sb '"
            ++ (colors !! 1)
            ++ "' -sf '"
            ++ (colors !! 15)
            ++ "' -fn 'Ubuntu:pixelsize=11:antialias=true:hinting=true' -h 22 -i -f -p 'Run: '"
        )
    ),
    -- TODO I give up, this just won't work how I want ...
    -- ("M-f", spawn myTerminal ++ " -e ." ++ myFileManager ++ ""),
    ("M-S-i", spawn "i3lock-fancy"),
    -- Kill windows
    ("M-S-q", kill1), -- Kill the currently focused client
    -- Workspaces
    ("M-<Tab>", toggleWS),
    -- Increase/decrease spacing (gaps)
    ("M-u", decWindowSpacing 4), -- Decrease window spacing
    ("M-i", incWindowSpacing 4), -- Increase window spacing
    -- Multimedia keys
    ("<XF86Mail>", runOrRaise "thunderbird" (resource =? "thunderbird")),
    ("<XF86HomePage>", runOrRaise myBrowser (resource =? myBrowser)),
    ("<XF86AudioPrev>", spawn "playerctl previous"),
    ("<XF86AudioNext>", spawn "playerctl next"),
    ("<XF86AudioPlay>", spawn "playerctl play-pause"),
    ("<XF86AudioStop>", spawn "playerctl stop"),
    ("<XF86AudioLowerVolume>", spawn "pamixer --set-limit 100 -d 3"),
    ("<XF86AudioRaiseVolume>", spawn "pamixer --set-limit 100 -i 3"),
    ("<XF86AudioMute>", spawn "pamixer --set-limit 100 -t"),
    ("<XF86Display>", spawn "autorandr --cycle"),
    -- ("<XF86MonBrightnessUp>", spawn "light -A 5"),
    -- ("<XF86MonBrightnessDown>", spawn "light -U 5"),
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
  colors <- getWalColors
  -- xmproc <- spawnPipe "xmobar $HOME/.config/xmobar/xmobarrc"
  xmprocs <- mapM (\i -> spawnPipe $ "xmobar $HOME/.config/xmobar/xmobarrc -x " ++ show i) [0 .. numScreens - 1]
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
              -- logHook =
              --   dynamicLogWithPP $
              --     xmobarPP
              -- { ppOutput = hPutStrLn xmprocs,
              --   ppCurrent = xmobarColor (colors !! 14) "" . wrap "[" "]",
              --   ppVisible = xmobarColor (colors !! 13) "" . clickable,
              --   ppHidden = xmobarColor (colors !! 15) "" . wrap "*" "" . clickable,
              --   ppHiddenNoWindows = xmobarColor (colors !! 11) "" . clickable,
              --   ppTitle = xmobarColor (colors !! 14) "" . shorten 60,
              --   ppSep = "<fc=" ++ (colors !! 2) ++ "> | </fc>",
              --   ppUrgent = xmobarColor (colors !! 15) "" . wrap "!" "!",
              --   -- , ppExtras = [windowCount],
              --   ppOrder = \(ws : l : t : ex) -> [ws, l] ++ ex ++ [t]
              -- }
        }
      `additionalKeysP` myKeys colors
