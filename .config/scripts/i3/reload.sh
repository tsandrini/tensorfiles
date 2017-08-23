#!/usr/bin/env bash
# vim: set ts=8 sw=4 tw=0 et :

i3-msg restart
xrdb -load ~/.Xresources

killall dunst polybar

dunst &
polybar top_bar &
polybar bottom_bar &
