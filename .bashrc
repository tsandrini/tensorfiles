#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias git-pretty-graph="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"

# PS1='[\u@\h \W]\$ '

# Gitflow autocompletion
source ~/.git-flow.sh

# If in git repo, show branch name
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '

# Auto cd
shopt -s autocd
