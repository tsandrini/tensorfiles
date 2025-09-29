{
  programs.plasma = {
    enable = true;
    shortcuts = {
      "ActivityManager"."switch-to-activity-3d52e0a5-6b8b-46ed-ab1a-045f7923ace9" = [ ];
      "KDE Keyboard Layout Switcher"."Switch keyboard layout to Czech (QWERTY)" = [ ];
      "KDE Keyboard Layout Switcher"."Switch keyboard layout to English (US)" = [ ];
      "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" =
        "Meta+N,Meta+Alt+K,Switch to Next Keyboard Layout";
      "kaccess"."Toggle Screen Reader On and Off" = "Meta+Alt+S";
      "kcm_touchpad"."Disable Touchpad" = "Touchpad Off";
      "kcm_touchpad"."Enable Touchpad" = "Touchpad On";
      "kcm_touchpad"."Toggle Touchpad" = [
        "Touchpad Toggle"
        "Meta+Ctrl+Touchpad Toggle"
        "Meta+Ctrl+Zenkaku Hankaku,Touchpad Toggle"
        "Touchpad Toggle"
        "Meta+Ctrl+Touchpad Toggle"
        "Meta+Ctrl+Zenkaku Hankaku"
      ];
      "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
      "kmix"."decrease_volume" = "Volume Down";
      "kmix"."decrease_volume_small" = "Shift+Volume Down";
      "kmix"."increase_microphone_volume" = "Microphone Volume Up";
      "kmix"."increase_volume" = "Volume Up";
      "kmix"."increase_volume_small" = "Shift+Volume Up";
      "kmix"."mic_mute" = [
        "Microphone Mute"
        "Meta+Volume Mute,Microphone Mute"
        "Meta+Volume Mute,Mute Microphone"
      ];
      "kmix"."mute" = "Volume Mute";
      "ksmserver"."Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
      "ksmserver"."Lock Session" = [
        "Screensaver,Meta+L"
        "Screensaver,Lock Session"
      ];
      "ksmserver"."Log Out" = "Ctrl+Alt+Del";
      "ksmserver"."Log Out Without Confirmation" = "none,,Log Out Without Confirmation";
      "ksmserver"."LogOut" = "none,,Log Out";
      "ksmserver"."Reboot" = "none,,Reboot";
      "ksmserver"."Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
      "ksmserver"."Shut Down" = "none,,Shut Down";
      "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
      "kwin"."Cycle Overview" = [ ];
      "kwin"."Cycle Overview Opposite" = [ ];
      "kwin"."Decrease Opacity" = "none,,Decrease Opacity of Active Window by 5%";
      "kwin"."Edit Tiles" = "Meta+T";
      "kwin"."Expose" = "Ctrl+F9";
      "kwin"."ExposeAll" = [
        "Ctrl+F10"
        "Launch (C),Ctrl+F10"
        "Launch (C),Toggle Present Windows (All desktops)"
      ];
      "kwin"."ExposeClass" = "Ctrl+F7";
      "kwin"."ExposeClassCurrentDesktop" = [ ];
      "kwin"."Grid View" = "Meta+G";
      "kwin"."Increase Opacity" = "none,,Increase Opacity of Active Window by 5%";
      "kwin"."Kill Window" = "Meta+Ctrl+Esc";
      "kwin"."Move Tablet to Next Output" = [ ];
      "kwin"."MoveMouseToCenter" = "Meta+F6";
      "kwin"."MoveMouseToFocus" = "Meta+F5";
      "kwin"."MoveZoomDown" = [ ];
      "kwin"."MoveZoomLeft" = [ ];
      "kwin"."MoveZoomRight" = [ ];
      "kwin"."MoveZoomUp" = [ ];
      "kwin"."Overview" = "Meta+W";
      "kwin"."PoloniumCycleEngine" = "Meta+|,none,Polonium: Cycle Engine";
      "kwin"."PoloniumFocusAbove" = "Meta+K,none,Polonium: Focus Above";
      "kwin"."PoloniumFocusBelow" = "Meta+J,none,Polonium: Focus Below";
      "kwin"."PoloniumFocusLeft" = "Meta+H,none,Polonium: Focus Left";
      "kwin"."PoloniumFocusRight" = "Meta+L,none,Polonium: Focus Right";
      "kwin"."PoloniumInsertAbove" = "Meta+Shift+K,none,Polonium: Insert Above";
      "kwin"."PoloniumInsertBelow" = "Meta+Shift+J,none,Polonium: Insert Below";
      "kwin"."PoloniumInsertLeft" = "Meta+Shift+H,none,Polonium: Insert Left";
      "kwin"."PoloniumInsertRight" = "Meta+Shift+L,none,Polonium: Insert Right";
      "kwin"."PoloniumOpenSettings" = "Meta+\\\\,none,Polonium: Open Settings Dialog";
      "kwin"."PoloniumResizeAbove" = "Meta+Ctrl+K,none,Polonium: Resize Above";
      "kwin"."PoloniumResizeBelow" = "Meta+Ctrl+J,none,Polonium: Resize Below";
      "kwin"."PoloniumResizeLeft" = "Meta+Ctrl+H,none,Polonium: Resize Left";
      "kwin"."PoloniumResizeRight" = "Meta+Ctrl+L,none,Polonium: Resize Right";
      "kwin"."PoloniumRetileWindow" = "Meta+Shift+Space,none,Polonium: Retile Window";
      "kwin"."PoloniumSwitchBTree" = [ ];
      "kwin"."PoloniumSwitchHalf" = [ ];
      "kwin"."PoloniumSwitchKwin" = [ ];
      "kwin"."PoloniumSwitchMonocle" = [ ];
      "kwin"."PoloniumSwitchThreeColumn" = [ ];
      "kwin"."Setup Window Shortcut" = "none,,Setup Window Shortcut";
      "kwin"."Show Desktop" = "none,Meta+D,Peek at Desktop";
      "kwin"."Switch One Desktop Down" = "Meta+Ctrl+Down";
      "kwin"."Switch One Desktop Up" = "Meta+Ctrl+Up";
      "kwin"."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
      "kwin"."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
      "kwin"."Switch Window Down" = "Meta+Alt+Down";
      "kwin"."Switch Window Left" = "Meta+Alt+Left";
      "kwin"."Switch Window Right" = "Meta+Alt+Right";
      "kwin"."Switch Window Up" = "Meta+Alt+Up";
      "kwin"."Switch to Desktop 1" = "Meta+1,Ctrl+F1,Switch to Desktop 1";
      "kwin"."Switch to Desktop 10" = [ ];
      "kwin"."Switch to Desktop 11" = "none,,Switch to Desktop 11";
      "kwin"."Switch to Desktop 12" = "none,,Switch to Desktop 12";
      "kwin"."Switch to Desktop 13" = "none,,Switch to Desktop 13";
      "kwin"."Switch to Desktop 14" = "none,,Switch to Desktop 14";
      "kwin"."Switch to Desktop 15" = "none,,Switch to Desktop 15";
      "kwin"."Switch to Desktop 16" = "none,,Switch to Desktop 16";
      "kwin"."Switch to Desktop 17" = "none,,Switch to Desktop 17";
      "kwin"."Switch to Desktop 18" = "none,,Switch to Desktop 18";
      "kwin"."Switch to Desktop 19" = "none,,Switch to Desktop 19";
      "kwin"."Switch to Desktop 2" = "Meta+2,Ctrl+F2,Switch to Desktop 2";
      "kwin"."Switch to Desktop 20" = "none,,Switch to Desktop 20";
      "kwin"."Switch to Desktop 3" = "Meta+3,Ctrl+F3,Switch to Desktop 3";
      "kwin"."Switch to Desktop 4" = "Meta+4,Ctrl+F4,Switch to Desktop 4";
      "kwin"."Switch to Desktop 5" = "Meta+5,,Switch to Desktop 5";
      "kwin"."Switch to Desktop 6" = "Meta+6,,Switch to Desktop 6";
      "kwin"."Switch to Desktop 7" = "Meta+7,,Switch to Desktop 7";
      "kwin"."Switch to Desktop 8" = "Meta+8,,Switch to Desktop 8";
      "kwin"."Switch to Desktop 9" = "Meta+9,,Switch to Desktop 9";
      "kwin"."Switch to Next Desktop" = "none,,Switch to Next Desktop";
      "kwin"."Switch to Next Screen" = "none,,Switch to Next Screen";
      "kwin"."Switch to Previous Desktop" = "none,,Switch to Previous Desktop";
      "kwin"."Switch to Previous Screen" = "none,,Switch to Previous Screen";
      "kwin"."Switch to Screen 0" = "none,,Switch to Screen 0";
      "kwin"."Switch to Screen 1" = "none,,Switch to Screen 1";
      "kwin"."Switch to Screen 2" = "none,,Switch to Screen 2";
      "kwin"."Switch to Screen 3" = "none,,Switch to Screen 3";
      "kwin"."Switch to Screen 4" = "none,,Switch to Screen 4";
      "kwin"."Switch to Screen 5" = "none,,Switch to Screen 5";
      "kwin"."Switch to Screen 6" = "none,,Switch to Screen 6";
      "kwin"."Switch to Screen 7" = "none,,Switch to Screen 7";
      "kwin"."Switch to Screen Above" = "none,,Switch to Screen Above";
      "kwin"."Switch to Screen Below" = "none,,Switch to Screen Below";
      "kwin"."Switch to Screen to the Left" = "none,,Switch to Screen to the Left";
      "kwin"."Switch to Screen to the Right" = "none,,Switch to Screen to the Right";
      "kwin"."Toggle Night Color" = [ ];
      "kwin"."Toggle Window Raise/Lower" = "none,,Toggle Window Raise/Lower";
      "kwin"."Walk Through Last Used Desktops" = "Meta+Tab,none,Walk Through Last Used Desktops";
      "kwin"."Walk Through Windows" = "Alt+Tab";
      "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
      "kwin"."Walk Through Windows Alternative" = "none,,Walk Through Windows Alternative";
      "kwin"."Walk Through Windows Alternative (Reverse)" =
        "none,,Walk Through Windows Alternative (Reverse)";
      "kwin"."Walk Through Windows of Current Application" = "Alt+`";
      "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
      "kwin"."Walk Through Windows of Current Application Alternative" =
        "none,,Walk Through Windows of Current Application Alternative";
      "kwin"."Walk Through Windows of Current Application Alternative (Reverse)" =
        "none,,Walk Through Windows of Current Application Alternative (Reverse)";
      "kwin"."Window Above Other Windows" = "none,,Keep Window Above Others";
      "kwin"."Window Below Other Windows" = "none,,Keep Window Below Others";
      "kwin"."Window Close" = [
        "Alt+F4"
        "Meta+Q,Alt+F4,Close Window"
      ];
      "kwin"."Window Custom Quick Tile Bottom" = "none,,Custom Quick Tile Window to the Bottom";
      "kwin"."Window Custom Quick Tile Left" = "none,,Custom Quick Tile Window to the Left";
      "kwin"."Window Custom Quick Tile Right" = "none,,Custom Quick Tile Window to the Right";
      "kwin"."Window Custom Quick Tile Top" = "none,,Custom Quick Tile Window to the Top";
      "kwin"."Window Fullscreen" = "none,,Make Window Fullscreen";
      "kwin"."Window Grow Horizontal" = "none,,Expand Window Horizontally";
      "kwin"."Window Grow Vertical" = "none,,Expand Window Vertically";
      "kwin"."Window Lower" = "none,,Lower Window";
      "kwin"."Window Maximize" = "Meta+PgUp";
      "kwin"."Window Maximize Horizontal" = "none,,Maximize Window Horizontally";
      "kwin"."Window Maximize Vertical" = "none,,Maximize Window Vertically";
      "kwin"."Window Minimize" = "Meta+PgDown";
      "kwin"."Window Move" = "none,,Move Window";
      "kwin"."Window Move Center" = "none,,Move Window to the Center";
      "kwin"."Window No Border" = "none,,Toggle Window Titlebar and Frame";
      "kwin"."Window On All Desktops" = "none,,Keep Window on All Desktops";
      "kwin"."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
      "kwin"."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
      "kwin"."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
      "kwin"."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
      "kwin"."Window One Screen Down" = "none,,Move Window One Screen Down";
      "kwin"."Window One Screen Up" = "none,,Move Window One Screen Up";
      "kwin"."Window One Screen to the Left" = "none,,Move Window One Screen to the Left";
      "kwin"."Window One Screen to the Right" = "none,,Move Window One Screen to the Right";
      "kwin"."Window Operations Menu" = "Alt+F3";
      "kwin"."Window Pack Down" = "none,,Move Window Down";
      "kwin"."Window Pack Left" = "none,,Move Window Left";
      "kwin"."Window Pack Right" = "none,,Move Window Right";
      "kwin"."Window Pack Up" = "none,,Move Window Up";
      "kwin"."Window Quick Tile Bottom" = "Meta+Down";
      "kwin"."Window Quick Tile Bottom Left" = "none,,Quick Tile Window to the Bottom Left";
      "kwin"."Window Quick Tile Bottom Right" = "none,,Quick Tile Window to the Bottom Right";
      "kwin"."Window Quick Tile Left" = "Meta+Left";
      "kwin"."Window Quick Tile Right" = "Meta+Right";
      "kwin"."Window Quick Tile Top" = "Meta+Up";
      "kwin"."Window Quick Tile Top Left" = "none,,Quick Tile Window to the Top Left";
      "kwin"."Window Quick Tile Top Right" = "none,,Quick Tile Window to the Top Right";
      "kwin"."Window Raise" = "none,,Raise Window";
      "kwin"."Window Resize" = "none,,Resize Window";
      "kwin"."Window Shade" = "none,,Shade Window";
      "kwin"."Window Shrink Horizontal" = "none,,Shrink Window Horizontally";
      "kwin"."Window Shrink Vertical" = "none,,Shrink Window Vertically";
      "kwin"."Window to Desktop 1" = "none,,Window to Desktop 1";
      "kwin"."Window to Desktop 10" = "none,,Window to Desktop 10";
      "kwin"."Window to Desktop 11" = "none,,Window to Desktop 11";
      "kwin"."Window to Desktop 12" = "none,,Window to Desktop 12";
      "kwin"."Window to Desktop 13" = "none,,Window to Desktop 13";
      "kwin"."Window to Desktop 14" = "none,,Window to Desktop 14";
      "kwin"."Window to Desktop 15" = "none,,Window to Desktop 15";
      "kwin"."Window to Desktop 16" = "none,,Window to Desktop 16";
      "kwin"."Window to Desktop 17" = "none,,Window to Desktop 17";
      "kwin"."Window to Desktop 18" = "none,,Window to Desktop 18";
      "kwin"."Window to Desktop 19" = "none,,Window to Desktop 19";
      "kwin"."Window to Desktop 2" = "none,,Window to Desktop 2";
      "kwin"."Window to Desktop 20" = "none,,Window to Desktop 20";
      "kwin"."Window to Desktop 3" = "none,,Window to Desktop 3";
      "kwin"."Window to Desktop 4" = "none,,Window to Desktop 4";
      "kwin"."Window to Desktop 5" = "none,,Window to Desktop 5";
      "kwin"."Window to Desktop 6" = "none,,Window to Desktop 6";
      "kwin"."Window to Desktop 7" = "none,,Window to Desktop 7";
      "kwin"."Window to Desktop 8" = "none,,Window to Desktop 8";
      "kwin"."Window to Desktop 9" = "none,,Window to Desktop 9";
      "kwin"."Window to Next Desktop" = "none,,Window to Next Desktop";
      "kwin"."Window to Next Screen" = "Meta+Shift+Right";
      "kwin"."Window to Previous Desktop" = "none,,Window to Previous Desktop";
      "kwin"."Window to Previous Screen" = "Meta+Shift+Left";
      "kwin"."Window to Screen 0" = "none,,Move Window to Screen 0";
      "kwin"."Window to Screen 1" = "none,,Move Window to Screen 1";
      "kwin"."Window to Screen 2" = "none,,Move Window to Screen 2";
      "kwin"."Window to Screen 3" = "none,,Move Window to Screen 3";
      "kwin"."Window to Screen 4" = "none,,Move Window to Screen 4";
      "kwin"."Window to Screen 5" = "none,,Move Window to Screen 5";
      "kwin"."Window to Screen 6" = "none,,Move Window to Screen 6";
      "kwin"."Window to Screen 7" = "none,,Move Window to Screen 7";
      "kwin"."disableInputCapture" = "Meta+Shift+Esc";
      "kwin"."view_actual_size" = "none,Meta+0,Zoom to Actual Size";
      "kwin"."view_zoom_in" = [
        "Meta++"
        "Meta+=,Meta++"
        "Meta+=,Zoom In"
      ];
      "kwin"."view_zoom_out" = "Meta+-";
      "mediacontrol"."mediavolumedown" = "none,,Media volume down";
      "mediacontrol"."mediavolumeup" = "none,,Media volume up";
      "mediacontrol"."nextmedia" = "Media Next";
      "mediacontrol"."pausemedia" = "Media Pause";
      "mediacontrol"."playmedia" = "none,,Play media playback";
      "mediacontrol"."playpausemedia" = "Media Play";
      "mediacontrol"."previousmedia" = "Media Previous";
      "mediacontrol"."stopmedia" = "Media Stop";
      "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
      "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
      "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
      "org_kde_powerdevil"."Hibernate" = "Hibernate";
      "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
      "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
      "org_kde_powerdevil"."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
      "org_kde_powerdevil"."PowerDown" = "Power Down";
      "org_kde_powerdevil"."PowerOff" = "Power Off";
      "org_kde_powerdevil"."Sleep" = "Sleep";
      "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
      "org_kde_powerdevil"."Turn Off Screen" = [ ];
      "org_kde_powerdevil"."powerProfile" = [
        "Battery"
        "Meta+B,Battery"
        "Meta+B,Switch Power Profile"
      ];
      "plasmashell"."activate application launcher" = [
        "Meta"
        "Alt+F1,Meta"
        "Alt+F1,Activate Application Launcher"
      ];
      "plasmashell"."activate task manager entry 1" = "none,Meta+1,Activate Task Manager Entry 1";
      "plasmashell"."activate task manager entry 10" = "none,,Activate Task Manager Entry 10";
      "plasmashell"."activate task manager entry 2" = "none,Meta+2,Activate Task Manager Entry 2";
      "plasmashell"."activate task manager entry 3" = "none,Meta+3,Activate Task Manager Entry 3";
      "plasmashell"."activate task manager entry 4" = "none,Meta+4,Activate Task Manager Entry 4";
      "plasmashell"."activate task manager entry 5" = "none,Meta+5,Activate Task Manager Entry 5";
      "plasmashell"."activate task manager entry 6" = "none,Meta+6,Activate Task Manager Entry 6";
      "plasmashell"."activate task manager entry 7" = "none,Meta+7,Activate Task Manager Entry 7";
      "plasmashell"."activate task manager entry 8" = "none,Meta+8,Activate Task Manager Entry 8";
      "plasmashell"."activate task manager entry 9" = "none,Meta+9,Activate Task Manager Entry 9";
      "plasmashell"."clear-history" = "none,,Clear Clipboard History";
      "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
      "plasmashell"."cycle-panels" = "Meta+Alt+P";
      "plasmashell"."cycleNextAction" = "none,,Next History Item";
      "plasmashell"."cyclePrevAction" = "none,,Previous History Item";
      "plasmashell"."manage activities" = "none,Meta+Q,Show Activity Switcher";
      "plasmashell"."next activity" = "Meta+A,none,Walk through activities";
      "plasmashell"."previous activity" = "Meta+Shift+A,none,Walk through activities (Reverse)";
      "plasmashell"."repeat_action" = "none,,Manually Invoke Action on Current Clipboard";
      "plasmashell"."show dashboard" = "Ctrl+F12";
      "plasmashell"."show-barcode" = "none,,Show Barcode…";
      "plasmashell"."show-on-mouse-pos" = "Meta+V";
      "plasmashell"."stop current activity" = "Meta+S";
      "plasmashell"."switch to next activity" = "none,,Switch to Next Activity";
      "plasmashell"."switch to previous activity" = "none,,Switch to Previous Activity";
      "plasmashell"."toggle do not disturb" = "none,,Toggle do not disturb";
      "services/org.flameshot.Flameshot.desktop"."_launch" = "Print";
      "services/org.kde.krunner.desktop"."_launch" = [
        "Search"
        "Meta+D"
        "Alt+F2"
        "Alt+Space"
      ];
      "services/org.kde.spectacle.desktop"."_launch" = "Meta+Shift+S";
      "services/org.wezfurlong.wezterm.desktop"."_launch" = "Meta+Return";
    };
    configFile = {
      "baloofilerc"."General"."dbVersion" = 2;
      "baloofilerc"."General"."exclude filters" =
        "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
      "baloofilerc"."General"."exclude filters version" = 9;
      "dolphinrc"."General"."ViewPropsTimestamp" = "2025,9,4,17,0,23.498";
      "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = false;
      "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 22;
      "kactivitymanagerdrc"."activities"."3d52e0a5-6b8b-46ed-ab1a-045f7923ace9" = "Default";
      "kactivitymanagerdrc"."main"."currentActivity" = "3d52e0a5-6b8b-46ed-ab1a-045f7923ace9";
      "kcminputrc"."Libinput/1739/0/Synaptics TM3471-020"."NaturalScroll" = true;
      "kcminputrc"."Libinput/1739/0/Synaptics TM3471-020"."PointerAcceleration" = 0.300;
      "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."NaturalScroll" = true;
      "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "820,584";
      "kdeglobals"."DirSelect Dialog"."Splitter State" =
        "\x00\x00\x00\xff\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x8c\x00\x00\x02\xa8\x00\xff\xff\xff\xff\x01\x00\x00\x00\x01\x00";
      "kdeglobals"."KFileDialog Settings"."Allow Expansion" = false;
      "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" = true;
      "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = true;
      "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
      "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
      "kdeglobals"."KFileDialog Settings"."Show Full Path" = false;
      "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = true;
      "kdeglobals"."KFileDialog Settings"."Show Preview" = false;
      "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
      "kdeglobals"."KFileDialog Settings"."Show hidden files" = false;
      "kdeglobals"."KFileDialog Settings"."Sort by" = "Name";
      "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
      "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
      "kdeglobals"."KFileDialog Settings"."Sort reversed" = false;
      "kdeglobals"."KFileDialog Settings"."Speedbar Width" = 138;
      "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
      "kdeglobals"."WM"."activeBackground" = "139,117,109";
      "kdeglobals"."WM"."activeBlend" = "139,117,109";
      "kdeglobals"."WM"."activeForeground" = "220,210,205";
      "kdeglobals"."WM"."inactiveBackground" = "154,147,143";
      "kdeglobals"."WM"."inactiveBlend" = "154,147,143";
      "kdeglobals"."WM"."inactiveForeground" = "220,210,205";
      "kscreenlockerrc"."Daemon"."Timeout" = 10;
      "kwalletrc"."Wallet"."First Use" = false;
      "kwinrc"."Activities/LastVirtualDesktop"."3d52e0a5-6b8b-46ed-ab1a-045f7923ace9" =
        "65bd3509-2757-43ec-9649-b7df524e74df";
      "kwinrc"."Desktops"."Id_1" = "6e66b58e-0ff5-4571-b280-e90032c3a093";
      "kwinrc"."Desktops"."Id_10" = "8b789658-f59f-4dee-a4e0-c8f9a511a605";
      "kwinrc"."Desktops"."Id_2" = "65bd3509-2757-43ec-9649-b7df524e74df";
      "kwinrc"."Desktops"."Id_3" = "7757d524-01b8-4682-a888-3ce5c5ddc2db";
      "kwinrc"."Desktops"."Id_4" = "8590eec1-aff4-425c-954a-773856abe54c";
      "kwinrc"."Desktops"."Id_5" = "af46927b-c1e3-424c-b9e8-4467d891c64d";
      "kwinrc"."Desktops"."Id_6" = "3c8bf0d8-8b75-4d51-8356-f3efba281b79";
      "kwinrc"."Desktops"."Id_7" = "3026e778-35ec-458e-a659-f2e2b8b7a690";
      "kwinrc"."Desktops"."Id_8" = "7502cd81-6238-4d59-9653-977d8e1b6add";
      "kwinrc"."Desktops"."Id_9" = "f1df936d-a4e7-4a8f-afff-ac92369f5ee9";
      "kwinrc"."Desktops"."Number" = 10;
      "kwinrc"."Desktops"."Rows" = 1;
      "kwinrc"."NightColor"."Active" = true;
      "kwinrc"."NightColor"."DayTemperature" = 5000;
      "kwinrc"."NightColor"."NightTemperature" = 4300;
      "kwinrc"."Plugins"."diminactiveEnabled" = true;
      "kwinrc"."Plugins"."kwin-walk-through-desktopsEnabled" = true;
      "kwinrc"."Plugins"."magiclampEnabled" = true;
      "kwinrc"."Plugins"."poloniumEnabled" = true;
      "kwinrc"."Plugins"."sheetEnabled" = true;
      "kwinrc"."Plugins"."slidebackEnabled" = true;
      "kwinrc"."Plugins"."squashEnabled" = false;
      "kwinrc"."Plugins"."wobblywindowsEnabled" = true;
      "kwinrc"."Script-polonium"."MaximizeSingle" = true;
      "kwinrc"."TabBox"."LayoutName" = "compact";
      "kwinrc"."Tiling"."padding" = 4;
      "kwinrc"."Tiling/71c6d035-136b-5699-bb1b-4270e10fabd5"."tiles" =
        "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.5},{\"width\":0.5}]}";
      "kwinrc"."Xwayland"."Scale" = 1;
      "kwinrulesrc"."6c469ce4-7558-4d57-af6e-3e855577b3fa"."Description" =
        "Hide titlebars and window frames";
      "kwinrulesrc"."6c469ce4-7558-4d57-af6e-3e855577b3fa"."noborder" = true;
      "kwinrulesrc"."6c469ce4-7558-4d57-af6e-3e855577b3fa"."noborderrule" = 2;
      "kwinrulesrc"."6c469ce4-7558-4d57-af6e-3e855577b3fa"."wmclass" = ".*";
      "kwinrulesrc"."6c469ce4-7558-4d57-af6e-3e855577b3fa"."wmclassmatch" = 3;
      "kwinrulesrc"."General"."count" = 1;
      "kwinrulesrc"."General"."rules" = "6c469ce4-7558-4d57-af6e-3e855577b3fa";
      "kxkbrc"."Layout"."DisplayNames" = ",";
      "kxkbrc"."Layout"."LayoutList" = "cz,us";
      "kxkbrc"."Layout"."Use" = true;
      "kxkbrc"."Layout"."VariantList" = "qwerty,";
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
      "plasma-localerc"."Formats"."LC_MEASUREMENT" = "cs_CZ.UTF-8";
      "plasma-localerc"."Formats"."LC_MONETARY" = "cs_CZ.UTF-8";
      "plasma-localerc"."Formats"."LC_PAPER" = "cs_CZ.UTF-8";
      "plasma-localerc"."Formats"."LC_TELEPHONE" = "cs_CZ.UTF-8";
      "plasmanotifyrc"."Applications/firefox"."Seen" = true;
      "plasmanotifyrc"."Applications/thunderbird"."Seen" = true;
      "spectaclerc"."ImageSave"."translatedScreenshotsFolder" = "Screenshots";
      "spectaclerc"."VideoSave"."translatedScreencastsFolder" = "Screencasts";
      "systemsettingsrc"."KFileDialog Settings"."detailViewIconSize" = 128;
    };
    dataFile = {

    };
  };
}
