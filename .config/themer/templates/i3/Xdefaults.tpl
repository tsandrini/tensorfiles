URxvt*font: \
        xft:MesloLGM Nerd Font:style=RegularForPowerline:pixelsize=17:antialias=true:hinting=true, \
        xft:TerminessTTF Nerd Font:style=Medium:pixelsize=17:antialias=true:hinting=true
URxvt*boldFont: \
        xft:MesloLGM Nerd Font:style=Bold:pixelsize=17:antialias=true:hinting=true, \
        xft:TerminessTTF Nerd Font:style=Bold:pixelsize=17:antialias=true:hinting=true
URxvt*italicFont: \
        xft:MesloLGM Nerd Font:style=Italic:pixelsize=17:antialias=true:hinting=true, \
        xft:TerminessTTF Nerd Font:style=Italic:pixelsize=17:antialias=true:hinting=true
URxvt*boldItalicFont: \
        xft:MesloLGM Nerd Font:style=Bold Italic:pixelsize=17:antialias=true:hinting=true, \
        xft:TerminessTTF Nerd Font:style=Bold Italic:pixelsize=17:antialias=true:hinting=true

*.background: {% if background %}{{ background }}{% else %}{{ black }}{% endif %}
*.foreground: {% if foreground %}{{ foreground }}{% else %}{{ white }}{% endif %}
*.cursorColor: {{ white }}

! black
*.color0: {{ black }}
*.color8: {{ alt_black }}
! red
*.color1: {{ red }}
*.color9: {{ alt_red }}
! green
*.color2: {{ green }}
*.color10: {{ alt_green }}
! yellow
*.color3: {{ yellow }}
*.color11: {{ alt_yellow }}
! blue
*.color4: {{ blue }}
*.color12: {{ alt_blue }}
! magenta
*.color5: {{ magenta }}
*.color13: {{ alt_magenta }}
! cyan
*.color6: {{ cyan }}
*.color14: {{ alt_cyan }}
! white
*.color7: {{ white }}
*.color15: {{ alt_white }}
! underline when default
*.colorUL: {% if underline %}{{ underline }}{% else %}{{ white }}{% endif %}

URxvt.internalBorder: 0
URxvt.externalBorder: 0

URxvt.scrollTtyOutput:   false
URxvt.scrollWithBuffer:  true
URxvt.scrollTtyKeypress: true

URxvt*.saveLines: 500
URxvt*.scrollBar: false

URxvt*iso14755: false
URxvt*iso14755_52: false

URxvt.imLocate: cs_CZ.UTF-8

URxvt.perl-ext-common : default,selection-autotransform,url-select,keyboard-select,matcher,resize-font
URxvt.perl-ext        : default,clipboard

URxvt.keysym.M-c:   perl:clipboard:copy
URxvt.keysym.M-v:   perl:clipboard:paste

URxvt.url-select.underline: true
urxvt*urlLauncher: /usr/bin/chromium
urxvt*matcher.button: 1
urxvt*matcher.pattern.1: \\bwww\\.[\\w-]+\\.[\\w./?&@#-]*[\\w/-]

URxvt*.transparent: true
URxvt*.shading: 20

URxvt*buffered: false

rofi.fullscreen: false
rofi.fake-transparency: false
rofi.opacity: 90
rofi.separator-style: dash
rofi.font: {{ fontName  }} 20
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

