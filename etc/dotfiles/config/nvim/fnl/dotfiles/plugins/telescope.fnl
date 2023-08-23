(module dotfiles.plugins.telescope
  {autoload {nvim aniseed.nvim}})


(let [tele (require :telescope)]
  (tele.setup {"defaults" {"prompt_prefix" "🔍"}}))
