#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# PS1='[\u@\h \W]\$ '

# Gitflow autocompletion
source ~/.git-flow.sh

PS1="\[\033[48;5;27m\]\u\[$(tput sgr0)\]\[\033[48;5;27m\]@\h \[$(tput sgr0)\]\[\033[38;5;27m\]\[\033[48;5;9m\] \[$(tput sgr0)\]\[\033[48;5;9m\]\W \[$(tput sgr0)\]\[\033[38;5;9m\]\$(__git_ps1 '  %s ')\[\033[38;5;9m\]\[$(tput sgr0)\]\[\033[38;5;15m\]\[$(tput sgr0)\]\[$(tput bold)\] \\$ \[$(tput sgr0)\]"

# Auto cd
shopt -s autocd

# Colorize grep
alias grep='grep --color=auto'

# Colorize diff
alias diff='diff --color=auto'

# Colorize ls
alias ls='ls --color=auto'

# Dynamicily resize line width by window width
shopt -s checkwinsize
