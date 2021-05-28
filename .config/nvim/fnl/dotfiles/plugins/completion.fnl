(module dotfiles.plugins.completion
  {autoload {nvim aniseed.nvim}
  require-macros [dotfiles.macros]})


(augroup completion
  (autocmd :BufEnter "*" "lua require'completion'.on_attach()"))

(nvim.set_keymap :i :<Tab> "pumvisible() ? '<C-n>' : '<Tab>'" {:expr true :noremap true})
(nvim.set_keymap :i :<S-Tab> "pumvisible() ? '<C-p>' : '<S-Tab>'" {:expr true :noremap true})

(nvim.ex.set "completeopt=menuone,noinsert,noselect")
(nvim.ex.set "shortmess+=c")

(set nvim.g.completion_chain_complete_list
     {"default" {"default" [ {"complete_items" ["snippet" "ts"]}]}
      "tex" {"default" [ {"complete_items" ["snippet" "tags"]}]}})
