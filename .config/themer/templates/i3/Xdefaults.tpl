*faceName:Menlo for Powerline
*faceSize:14
URxvt*.font: xft:Menlo for Powerline:pixelsize=14

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

URxvt*.saveLines: 65535
URxvt*.scrollBar: false

URxvt.perl-ext-common : default,selection-autotransform,url-select,keyboard-select,rotate-colors,matcher,resize-font
URxvt.perl-ext        : default,clipboard

URxvt.keysym.M-Escape: perl:keyboard-select:activate
URxvt.keysym.M-s: perl:keyboard-select:search
URxvt.keysym.M-u: perl:url-select:select_next
URxvt.keysym.M-c:   perl:clipboard:copy
URxvt.keysym.M-v:   perl:clipboard:paste
URxvt.keysym.M-C-v: perl:clipboard:paste_escaped

URxvt.url-select.launcher  : chromium
URxvt.url-select.underline : true
URxvt.url-select.button    : 2

URxvt*.transparent: true
URxvt*.shading: 30

Xft*.antialias: true
Xft*.hinting: true
Xft*.hintstyle: hintslight

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

