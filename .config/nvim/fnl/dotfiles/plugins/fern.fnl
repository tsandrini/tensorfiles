(module dotfiles.plugins.fern
  {autoload {nvim aniseed.nvim}
  require-macros [dotfiles.macros]})


; Disable netrw
(set nvim.g.loaded_netrw false)
(set nvim.g.loaded_netrwPlugin false)
(set nvim.g.loaded_netrwSettings false)
(set nvim.g.loaded_netrwFileHandlers false)

; Enable nerdfont
(set nvim.g.fern#renderer "nerdfont")

;; Key mappings
(set nvim.g.fern#disable_default_mappings true)

; I only use fern as a drawer opened via `m` and closed either by `q` or by
; selecting and opening a node
(nvim.set_keymap :n :m ":Fern . -drawer -reveal=% -width=35 <CR><C-w>=" {:noremap true :silent true})

; Setup close action for a further "open and close" mapping
(nvim.set_keymap :n "<plug>(fern-close-drawer)" ":<C-u>FernDo close -drawer -stay<CR>" {:noremap true :silent true})


(defn fern_init []
  (nvim.buf_set_keymap :0 :n "<plug>(fern-action-custom-open-expand-collapse)" "fern#smart#leaf(\"<plug>(fern-action-open)<plug>(fern-close-drawer)\", \"<plug>(fern-action-expand)\", \"<plug>(fern-action-collapse)\")" {:expr true})
  (nvim.buf_set_keymap :0 :n :q ":<C-u>quit<CR>" {})
  (nvim.buf_set_keymap :0 :n :n "<plug>(fern-action-new-path)" {})
  (nvim.buf_set_keymap :0 :n :d "<plug>(fern-action-remove)" {})
  (nvim.buf_set_keymap :0 :n :m "<plug>(fern-action-move)" {})
  (nvim.buf_set_keymap :0 :n :M "<plug>(fern-action-rename)" {})
  (nvim.buf_set_keymap :0 :n :<C-h> "<plug>(fern-action-hidden-toggle)" {})
  (nvim.buf_set_keymap :0 :n :r "<plug>(fern-action-reload)" {})
  (nvim.buf_set_keymap :0 :n :l "<plug>(fern-action-custom-open-expand-collapse)" {})
  (nvim.buf_set_keymap :0 :n :h "<plug>(fern-action-collapse)" {})
  (nvim.buf_set_keymap :0 :n :<2-LeftMouse> "<plug>(fern-action-custom-open-expand-collapse)" {})
  (nvim.buf_set_keymap :0 :n :<CR> "<plug>(fern-action-custom-open-expand-collapse)" {}))

(augroup fern_group
  (autocmd :Filetype :fern "lua require('dotfiles.plugins.fern').fern_init()")
  (autocmd :Filetype :fern "call glyph_palette#apply()"))
