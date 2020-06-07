--------------------------------------------------------------------------------
-- IMPORTS
--------------------------------------------------------------------------------

import XMonad -- standard xmonad library
import XMonad.Config.Desktop -- default desktopConfig

-- Used to make sure my autostart script is run only on login
import XMonad.Util.SpawnOnce

-- Simplifies the syntax for defining keybindings
import XMonad.Util.EZConfig
-- For starting and sending information to the xmobar status bar
import XMonad.Util.Run (spawnPipe,hPutStrLn)
-- Removes window borders if they aren't needed
import XMonad.Layout.NoBorders (smartBorders)
-- Allow gaps to be displayed around windows, for aesthetic purposes
import XMonad.Layout.Spacing

--------------------------------------------------------------------------------

-- For xmobar

-- Allows us to customise the logHook that sends information to xmobar
import XMonad.Hooks.DynamicLog
-- Provides tools to manipulate docks and panels, and to avoid overlapping them
import XMonad.Hooks.ManageDocks

-- For moving workspaces -- to be removed in next commit
import XMonad.Actions.CycleWS

--------------------------------------------------------------------------------
-- VARIABLES AND DEFAULT PROGRAMS
--------------------------------------------------------------------------------

-- The modifier key to be used for most keybindings
-- I have it set to super (the Windows key)
myModMask  = mod4Mask

-- Default applications
myTerminal     = "alacritty"
myEditor       = myTerminal ++ " -e nvim "
myBrowser      = "qutebrowser"
myHeavyBrowser = "firefox"
myGuiFileManager = "pcmanfm"
myPdfReader    = "zathura"
myScreenshot   = "spectacle"

-- Command to use for the various menus
--  myLauncher is the menu for opening applications
--  myMenu is used for displaying user-generated menus (my shell menu scripts)
-- dmenu is a much simpler option, but with less eye-candy
--myLauncher     = "dmenu_run"
--myMenu         = "dmenu -i -p"
-- rofi looks much nicer, but is less minimal and the default theme is ugly
myLauncher     = "rofi -show drun -theme " ++ rofiTheme "blurry-icons-centre"
myMenu         = "rofi -dmenu -i -p"

--------------------------------------------------------------------------------

-- Config locations

-- Directory for storing xmonad-related config files
myConfigDir   = "~/.config/xmonad/src/"
-- The script run to recompile xmonad after config changes
myBuildScript = "~/.config/xmonad/build"
-- Programs to start automatically on login
myAutostart   = myConfigDir ++ "autostart.sh"
-- Config for the xmobar status bar
myXmobarrc    = myConfigDir ++ "xmobarrc.hs"
-- Directory that contains all my rofi themes, for the rofi menu program
rofiTheme theme = "~/.config/rofi/themes/" ++ theme ++ ".rasi"

--------------------------------------------------------------------------------
-- MY FUNCTIONS AND SCRIPTS
--------------------------------------------------------------------------------

-- Edit a file if it exists, otherwise show an error
editIfExists :: [Char] -> [Char]
editIfExists fileName = "[ -f " ++ fileName ++ " ] \
                          \&& " ++ myEditor ++ fileName ++ " \
                          \||  notify-send \"" ++ fileName ++ " not found\""

-- Convert strings to arguments (multiple words treated as one)
args :: [[Char]] -> [Char]
args arguments = " " ++ unwords (map show arguments)

--------------------------------------------------------------------------------
-- KEYBINDINGS
--------------------------------------------------------------------------------

myKeys = [ ("M-q",         spawn myBuildScript)
         , ("C-<Escape>",  spawn myLauncher)  -- launch dmenu with Super
         -- Moving workspaces
         , ("M-<Left>",    prevWS)
         , ("M-S-<Right>", nextWS)
         , ("M-<Left>",    shiftToPrev)
         , ("M-S-<Right>", shiftToNext)
         -- Application shortcuts
         , ("M-<Return>",  spawn myTerminal)
         , ("M-e",         spawn myEditor)
         , ("M-S-e",       spawn (editIfExists "Chords/index.txt"))
         , ("M-w",         spawn myBrowser)
         , ("M-S-w",       spawn myHeavyBrowser)
         , ("M-f",         spawn myGuiFileManager)
         , ("M-z",         spawn "zoom")
         , ("<Print>",     spawn myScreenshot)  -- print screen
         -- Menu scripts
         , ("M-S-p M-S-p", spawn ("menu-edit-script" ++ (args[myMenu,myEditor])))
         , ("M-S-p M-S-e", spawn ("menu-edit-config" ++ (args[myMenu,myEditor])))
         , ("M-S-p M-S-c", spawn ("menu-change-colourscheme" ++ (args[myMenu])))
         , ("M-S-p M-S-z", spawn ("menu-read-pdf" ++ (args[myMenu,myPdfReader])))
         ]

--------------------------------------------------------------------------------
-- AESTHETICS
--------------------------------------------------------------------------------

mySpacing = spacingRaw False                -- smartBorder (border only for >1 window)
                       (Border 5 5 5 5)     -- screenBorder
                       True                 -- screenBorderEnabled
                       (Border 5 5 5 5)     -- windowBorder
                       True                 -- windowBorderEnabled

--------------------------------------------------------------------------------
-- MANAGEHOOK
--------------------------------------------------------------------------------

myManageHook = composeAll . concat $
    [ [ className =? c --> doFloat           | c <- myFloatClasses ]
    , [ title     =? t --> doFloat           | t <- myFloatTitles ]
    --, [ className =? c --> doShift "3:WWW"   | c <- browsers ]
    ]
  where myFloatClasses = ["Gimp","conky","plasmashell","vlc","Caprine", "Nitrogen"]
        myFloatTitles  = ["Whisker Menu"]
        --browsers       = ["Firefox-bin","firefox"]

--------------------------------------------------------------------------------
-- WORKSPACES
--------------------------------------------------------------------------------

myWorkspaces :: [String]
myWorkspaces = ["1","2","3","4","5","6","7","8","9"]

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

myCurrentWorkspacePrinter :: String -> String
myHiddenWorkspacePrinter :: String -> String
myHiddenNoWindowsWorkspacePrinter :: String -> String
myCurrentWorkspacePrinter workspaceName = "[●]"
myHiddenWorkspacePrinter workspaceName = "●"
myHiddenNoWindowsWorkspacePrinter workspaceName = "○"

main = do
    -- spawnPipe starts xmobar and returns a handle - named xmproc - for input
    xmproc <- spawnPipe ("xmobar " ++ myXmobarrc)
    -- Applies this config file over the default config for desktop use
    xmonad $ desktopConfig
        { modMask     = myModMask
        , terminal    = myTerminal
        , manageHook  = manageDocks <+> manageHook desktopConfig <+> myManageHook
        , layoutHook  = mySpacing $ avoidStruts $ smartBorders (layoutHook desktopConfig)
        -- The information to send to xmobar, through the handle we defined earlier
        , logHook     = dynamicLogWithPP xmobarPP
                            { ppOutput = hPutStrLn xmproc
                            , ppOrder  = \(ws:l:t:ex) -> [ws]  -- Only send workspace information
                            , ppCurrent = xmobarColor "white" "" . myCurrentWorkspacePrinter
                            , ppHidden  = xmobarColor "white" "" . myHiddenWorkspacePrinter
                            , ppHiddenNoWindows = xmobarColor "white" "" . myHiddenNoWindowsWorkspacePrinter
                            }
        , workspaces  = myWorkspaces
        , startupHook = spawnOnce myAutostart
        }
        `additionalKeysP` myKeys
