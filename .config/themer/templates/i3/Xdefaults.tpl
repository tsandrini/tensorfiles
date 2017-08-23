!-------------------------------!
!                               !
!   Xresources by tsandrini     !
!                               !
!-------------------------------!


! --- \section{sys colors} --- !


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


! --- \section(xft settings) -- !


Xft.autohint: 0
Xft*antialias: true
Xft.hinting: true
Xft.hintstyle: hintslight
Xft*dpi: 96
Xft.lcdfilter: lcddefault


! --- \section{URXVT} --- !


! --- \subsection{font settings} --- !

URxvt*font: \
        xft:DejaVuSansMono Nerd Font:style=Book:pixelsize=18:antialias=true:hinting:true, \
        xft:TerminessTTF Nerd Font:style=Medium:pixelsize=13:antialias=true:hinting=true
URxvt*boldFont: \
        xft:DejaVuSansMono Nerd Font:style=Bold:pixelsize=18:antialias=true:hinting:true, \
        xft:TerminessTTF Nerd Font:style=Bold:pixelsize=13:antialias=true:hinting=true
URxvt*italicFont: \
        xft:DejaVuSansMono Nerd Font:style=Oblique:pixelsize=18:antialias=true:hinting:true, \
        xft:TerminessTTF Nerd Font:style=Italic:pixelsize=13:antialias=true:hinting=true
URxvt*boldItalicFont: \
        xft:DejaVuSansMono Nerd Font:style=Bold Oblique:pixelsize=18:antialias=true:hinting:true, \
        xft:TerminessTTF Nerd Font:style=Bold Italic:pixelsize=13:antialias=true:hinting=true



! --- \subsection{appearence} --- !


URxvt.internalBorder: 0
URxvt.externalBorder: 0

URxvt*scrollBar: false
URxvt*cursorBlink: true
URxvt*cursorUnderline: true

URxvt*.transparent: false
URxvt.allow_bold: true
URxvt*background: rgba:0000/0000/0000/9999
URxvt*depth: 32

! --- \subsection{general settings} --- !


URxvt*iso14755: false
URxvt*iso14755_52: false

URxvt.imLocate: cs_CZ.UTF-8


! --- \subsection{extensions} --- !


URxvt.perl-ext-common : default,selection-autotransform,url-select,keyboard-select,matcher,resize-font
URxvt.perl-ext        : default,clipboard

URxvt.keysym.M-c:   perl:clipboard:copy
URxvt.keysym.M-v:   perl:clipboard:paste

URxvt.perl-ext-common: default,matcher
URxvt.url-launcher: /usr/bin/xdg-open
URxvt.matcher.button: 1


! --- \subsection{performance} --- !


URxvt.scrollTtyOutput:   false
URxvt.scrollWithBuffer:  true
URxvt.scrollTtyKeypress: true

URxvt*.saveLines: 1000

URxvt*skipBuiltinGlyphs: true
URxvt*skipScroll: true

URxvt*buffered: false


! --- \section{rofi} --- !

rofi.fullscreen: false
rofi.fake-transparency: false
rofi.opacity: 75
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
