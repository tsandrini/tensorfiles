(module dotfiles.plugins.lspsaga
  {autoload {nvim aniseed.nvim}})


(let [saga (require :lspsaga)]
  (saga.init_lsp_saga {}))

(let [lsp (require :lspconfig)]
  (lsp.pyright.setup {}))
