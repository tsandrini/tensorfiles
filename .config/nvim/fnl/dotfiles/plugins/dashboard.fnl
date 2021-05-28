(module dotfiles.plugins.dashboard
  {autoload {nvim aniseed.nvim}
  require-macros [dotfiles.macros]})


(set nvim.g.dashboard_default_executive "fzf")
(set nvim.g.dashboard_custom_header [
 " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗"
 " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║"
 " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║"
 " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║"
 " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║"
 " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝"
])

(augroup dashboard_hide_tabline
  (autocmd :Filetype :dashboard "set showtabline=0 | autocmd WinLeave <buffer> set showtabline=2"))
