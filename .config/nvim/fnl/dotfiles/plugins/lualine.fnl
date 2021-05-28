(module dotfiles.plugins.lualine
  {autoload {nvim aniseed.nvim}})


(let [lualine (require :lualine)]
  (lualine.setup {"options" {"theme" "auto"
                             "icons_enabled" true}
                  "sections" {"lualine_a" [["mode" {"upper" true}]]
                              "lualine_b" [["branch" {"icon" ""}]]
                              "lualine_c" [["filename" {"file_status" true}]]
                              "lualine_x" ["encoding" "fileformat" "filetype"]
                              "lualine_y" ["progress"]
                              "lualine_z" ["location"]}
                  "extensions" []
                  }))
