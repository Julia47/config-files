import XMonad
import XMonad.Util.Run(spawnPipe)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks (ToggleStruts(..),avoidStruts,docks,manageDocks, docksEventHook)
import XMonad.Hooks.FadeInactive
import XMonad.Util.EZConfig
import XMonad.ManageHook
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.EwmhDesktops
import qualified XMonad.Util.Loggers as Logr

import XMonad.Hooks.SetWMName
import XMonad.Layout.Spacing

import System.IO

import qualified Data.Map as M
import qualified Graphics.X11.ExtraTypes.XF86 as XF86
import qualified XMonad.Util.Brightness as Bright


--myXmonadBar = "dzen2 -x '0' -y '0' -h '24' -w '1420' -ta 'l' -fg '#FFFFFF' -bg '#1B1D1E'"
myXmonadBar = "dzen2 -dock -x '0' -w '1920' -ta 'l' -fg '#FFFFFF' -bg '#1B1D1E'"

main = do
   dzenLeftBar <- spawnPipe myXmonadBar
   xmonad $ defaultConfig
     { terminal    = myTerminal
     , logHook     = myLogHook dzenLeftBar >> fadeInactiveLogHook 0xeeeeeeee
     , modMask     = myModMask
     , borderWidth = myBorderWidth
     , workspaces  = myWorkspace
     --, manageHook  = myManagehook
     , layoutHook  = avoidStruts myLayoutHook
     --, layoutHook  = spacing 10 $ avoidStruts myLayoutHook
     , manageHook  = manageDocks <+> manageHook defaultConfig
     , handleEventHook = handleEventHook defaultConfig <+> docksEventHook <+> fullscreenEventHook
     , startupHook = setWMName "LG3D"
     , normalBorderColor        = "#001230"
     , focusedBorderColor       = "#00FFFF"
     } `additionalKeys` myKeys


myLayoutHook  = tiled ||| Mirror tiled ||| Full
  where
     tiled   = Tall nmaster delta ratio
     nmaster = 1
     ratio   = 1/2
     delta   = 3/100
myTerminal    = "/usr/bin/gnome-terminal"
myModMask     = mod4Mask -- Alt клавиша (или Super_L)
myBorderWidth = 0
myWorkspace :: [String]
myWorkspace = ["1:dev", "2:dev", "3:web", "4:other", "5:media","6:msg"] ++ map show [7..9]
myManagehook :: ManageHook
myManagehook = composeAll . concat $
  [
    [className =? c --> doShift "3:web"            | c <- myWeb],
    [className =? c --> doShift "5:media"          | c <- myMedia],
    [className =? c --> doShift "6:msg"            | c <- myMessg],
    [manageDocks]
  ]
  where
    myWeb       = ["firefox", "vivaldi", "opera"]
    myMedia     = ["zathura", "evince", "rhytmbox"]
    myMessg     = ["viber", "Discord"]


myKeys =
  [
    ((mod4Mask .|. shiftMask, xK_z), spawn "xscreensaver-command -lock"),
    ((0                     , 0x1008FF11), spawn "amixer -q sset Master 5%-"),
    ((0                     , 0x1008FF13), spawn "amixer -q sset Master 5%+"),
    ((0                     , 0x1008FF12), spawn "amixer set Master toggle")
  ]
  ++
  [
    ((0, 0xFF61), spawn "scrot -q 1 $HOME/pictures/screenshots/%Y-%m-%d-%H:%M:%S.png"),
    ((mod4Mask .|. shiftMask, xK_n), spawn "nautilus -w"),
    ((mod4Mask .|. shiftMask, xK_t), spawn "thunar"),
    ((mod4Mask .|. shiftMask, xK_o), spawn "opera"),
    ((mod4Mask .|. shiftMask, xK_v), spawn "vivaldi"),
    ((mod4Mask .|. shiftMask, xK_r), spawn "rhythmbox"),
    ((mod4Mask .|. shiftMask, xK_s), spawn "steam"),
    ((mod4Mask .|. shiftMask, xK_p), spawn "gnome-screenshot -a")
  ]
  ++
  [
    ((mod4Mask, xK_Escape), spawn "/home/serhii/.bin/layout_kb_switcher.sh")
  ]
  ++
  [
    ((0, XF86.xF86XK_MonBrightnessUp), Bright.increase),       -- Increase screen brightness SUPER + 8/9
    ((0, XF86.xF86XK_MonBrightnessDown), Bright.decrease)
  ]
  ++
  -- [
  --   ((0, XF86.xF86XK_AudioNext), spawn "rhythmbox-client --next"),
  --   ((0, XF86.xF86XK_AudioPrev), spawn "rhythmbox-client --previous"),
  --   ((0, XF86.xF86XK_AudioStop), spawn "rhythmbox-client --play-pause"),
  --   ((0, XF86.xF86XK_AudioPlay), spawn "rhythmbox-client --play-pause")
  -- ]
  -- ++
  -- | MOCP music set
  [
    ((0, XF86.xF86XK_AudioNext), spawn "mocp -f"),
    ((0, XF86.xF86XK_AudioPrev), spawn "mocp -r"),
    ((0, XF86.xF86XK_AudioStop), spawn "mocp -P"),
    ((0, XF86.xF86XK_AudioPlay), spawn "mocp -P")
  ]

myBitmapsDir = "/home/my_user/.xmonad/dzen2"
myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ defaultPP
    {
        ppCurrent           =   dzenColor "#FF0022" "#1B1D1E" . pad
      , ppVisible           =   dzenColor "#00CCCC" "#1B1D1E" . pad
      , ppHidden            =   dzenColor "white" "#1B1D1E" . pad
      , ppHiddenNoWindows   =   dzenColor "#7b7b7b" "#1B1D1E" . pad
      , ppUrgent            =   dzenColor "#ff0000" "#1B1D1E" . pad
      , ppWsSep             =   " "
      , ppSep               =   "     "
      , ppLayout            =   dzenColor "#00EEEE" "#1B1D1E" .
                                (\x -> case x of
                                    "ResizableTall"             ->      "^i(" ++ myBitmapsDir ++ "/tall.xbm)"
                                    "Mirror ResizableTall"      ->      "^i(" ++ myBitmapsDir ++ "/mtall.xbm)"
                                    "Full"                      ->      "^i(" ++ myBitmapsDir ++ "/full.xbm)"
                                    "Simple Float"              ->      "~"
                                    _                           ->      x
                                )
      , ppExtras            =   [ (Logr.wrapL " Time: " "" (Logr.dzenColorL "#00FF00" "#1B1D1E" $ Logr.date "%R"))
                                , (Logr.wrapL " Data: " "" (Logr.dzenColorL "#00FF00" "#1B1D1E" $ Logr.date "%d %A [%m]"))
                                , (Logr.wrapL " Battery: " "" (Logr.dzenColorL "#FF00AA" "#1B1D1E" $ Logr.battery))
                                --, (Logr.wrapL "[" "]" (Logr.dzenColorL "#00AAAA" "#1B1D1E" $ (Logr.logCmd "slstatus -s")))
                                ]
      , ppTitle             =   (" " ++) . dzenColor "#FFAA00" "#1B1D1E" . shorten 40 . dzenEscape
      , ppOrder             =   \(ws:wtall:titl:extr) -> [ws,wtall]++extr++[titl]
      , ppOutput            =   hPutStrLn h
    }
