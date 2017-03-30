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


rofi.color-enabled: true
!rofi.color-window: #273238, #273238, #1e2529
!rofi.color-normal: #273238, #c1c1c1, #273238, #394249, #ffffff
rofi.color-window: argb: EE000000, argb: EE000000, argb: EE000000
rofi.color-normal: argb: 00000000, #DEDEDE, argb: 00000000, #DEDEDE
rofi.color-active: #273238, #80cbc4, #273238, #394249, #80cbc4
rofi.color-urgent: #273238, #ff1844, #273238, #394249, #ff1844
