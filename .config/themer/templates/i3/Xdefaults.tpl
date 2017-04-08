URxvt*font: \
        xft:MesloLGM Nerd Font:style=RegularForPowerline:pixelsize=17:antialias=true:hinting=true, \
        xft:TerminessTTF Nerd Font:style=Medium:pixelsize=17:antialias=true:hinting=true
URxvt*boldFont: \
        xft:MesloLGM Nerd Font:style=Bold:pixelsize=17:antialias=true:hinting=true, \
        xft:TerminessTTF Nerd Font:style=Bold:pixelsize=17:antialias=true:hinting=true

URxvt*.background: {% if transparency %}[{{ transparency }}]{% endif %}{% if background %}{{ background }}{% else %}{{ black }}{% endif %}
URxvt*.foreground: {% if foreground %}{{ foreground }}{% else %}{{ white }}{% endif %}
URxvt*.cursorColor: {{ white }}

! black
URxvt*.color0: {{ black }}
URxvt*.color8: {{ alt_black }}
! red
URxvt*.color1: {{ red }}
URxvt*.color9: {{ alt_red }}
! green
URxvt*.color2: {{ green }}
URxvt*.color10: {{ alt_green }}
! yellow
URxvt*.color3: {{ yellow }}
URxvt*.color11: {{ alt_yellow }}
! blue
URxvt*.color4: {{ blue }}
URxvt*.color12: {{ alt_blue }}
! magenta
URxvt*.color5: {{ magenta }}
URxvt*.color13: {{ alt_magenta }}
! cyan
URxvt*.color6: {{ cyan }}
URxvt*.color14: {{ alt_cyan }}
! white
URxvt*.color7: {{ white }}
URxvt*.color15: {{ alt_white }}
! underline when default
URxvt*.colorUL: {% if underline %}{{ underline }}{% else %}{{ white }}{% endif %}

URxvt*.saveLines: 500
URxvt*.scrollBar: false

URxvt*iso14755: false
URxvt*iso14755_52: false

URxvt*letterSpace: -1
URxvt.imLocate: cs_CZ.UTF-8

URxvt.perl-ext-common : default,selection-autotransform,url-select,keyboard-select,matcher,resize-font
URxvt.perl-ext        : default,clipboard

URxvt.keysym.M-c:   perl:clipboard:copy
URxvt.keysym.M-v:   perl:clipboard:paste

URxvt.url-select.underline : true
URxvt.url-select.button    : 2
URxvt*urlLauncher: chromium

URxvt*.transparent: true
URxvt*.shading: 30

rofi.fullscreen: false
rofi.fake-transparency: false
rofi.opacity: 90
rofi.separator-style: dash
rofi.font: System San Francisco Display 18
rofi.color-enabled: true
rofi.width: 100
rofi.padding: 800
rofi.hide-scrollbar: true
rofi.location: 0
rofi.color-enabled: true
rofi.yoffset: 0
rofi.xoffset: 0
rofi.line-margin: 5

rofi.color-window:      argb:dc111111, argb:dc111111
! State:                'bg',          'fg',   'bgalt',       'hlbg',        'hlfg'
rofi.color-normal:      argb:00333333, #ffffff, argb:00333333, argb:00333333, {{ primary }}
rofi.color-urgent:      argb:00333333, #ffffff, argb:00333333, argb:00333333, {{ primary }}
rofi.color-active:      argb:00333333, #ffffff, argb:00333333, argb:00333333, {{ primary }}

