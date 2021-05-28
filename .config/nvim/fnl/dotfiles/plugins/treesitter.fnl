(module dotfiles.plugins.treesitter
  {autoload {nvim aniseed.nvim}})

(let [tree (require "nvim-treesitter.configs")]
  (tree.setup {"ensure_installed" ["bash" "bibtex" "c" "clojure" "comment" "cpp"
                                   "css" "dockerfile" "fennel" "graphql" "html"
                                   "java" "javascript" "jsdoc" "json" "julia"
                                   "latex" "lua" "nix" "php" "python" "r" "regex"
                                   "ruby" "rust" "typescript" "vue" "yaml" "haskell"]
               "ignore_install" []
               "highlight" {"enable" true
                            "disable" ["tex"]}}
               "incremental_selection" {"enable" true}
               "indent" {"enable" true}))
