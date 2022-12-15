(module dotfiles.plugins.easymotion
  {autoload {nvim aniseed.nvim}})

; Disable default mappings
(set nvim.g.EasyMotion_do_mapping false)

; Enable smartcase
(set nvim.g.EasyMotion_smartcase true)

(nvim.set_keymap :n "," "<plug>(easymotion-overwin-f2)" {})
