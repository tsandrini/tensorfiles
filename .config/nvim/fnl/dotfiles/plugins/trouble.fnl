(module dotfiles.plugins.trouble
  {autoload {nvim aniseed.nvim}})


(let [trouble (require :trouble)]
  (trouble.setup {}))
