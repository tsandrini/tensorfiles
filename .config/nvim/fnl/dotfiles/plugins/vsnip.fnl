(module dotfiles.plugins.vsnip
  {autoload {nvim aniseed.nvim}})

;(nvim.set_keymap :i :<C-j> "vsnip#expandable() ? '<plug>(vsnip-expand)' : '<C-j>'" {:expr true})
;(nvim.set_keymap :s :<C-j> "vsnip#expandable() ? '<plug>(vsnip-expand)' : '<C-j>'" {:expr true})
;
;(nvim.set_keymap :i :<C-l> "vsnip#available(1) ? '<plug>(vsnip-expand-or-jump)' : '<C-l>'" {:expr true})
;(nvim.set_keymap :s :<C-l> "vsnip#available(1) ? '<plug>(vsnip-expand-or-jump)' : '<C-l>'" {:expr true})
;
(nvim.set_keymap :i :<C-j> "vsnip#jumpable(1) ? '<plug>(vsnip-jump-next)' : '<C-j>'" {:expr true})
(nvim.set_keymap :s :<C-j> "vsnip#jumpable(1) ? '<plug>(vsnip-jump-next)' : '<C-j>'" {:expr true})
(nvim.set_keymap :i :<C-l> "vsnip#jumpable(-1) ? '<plug>(vsnip-jump-prev)' : '<C-l>'" {:expr true})
(nvim.set_keymap :s :<C-l> "vsnip#jumpable(-1) ? '<plug>(vsnip-jump-prev)' : '<C-l>'" {:expr true})

(set nvim.g.completion_enable_snippet "vim-vsnip")
(set nvim.g.vsnip_snippet_dir "~/.config/nvim/vsnips")
