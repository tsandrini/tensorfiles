(module dotfiles.mappings
  {require {nvim aniseed.nvim}})

(defn- noremap [mode from to]
  "Sets a mapping with {:noremap true}."
  (nvim.set_keymap mode from to {:noremap true}))


(set nvim.g.mapleader " ")
(set nvim.g.maplocalleader " ")


;; Remap escape to jk/kj for each mode
;; ----------------------------------------------
(noremap :i :jk :<esc>)
(noremap :i :kj :<esc>)
(noremap :c :jk :<c-c>)
(noremap :c :kj :<c-c>)
(noremap :t :jk :<c-\><c-n>)
(noremap :t :kj :<c-\><c-n>)
(noremap :v :jk :<esc>)
(noremap :v :kj :<esc>)
;; ----------------------------------------------


;; Tab manipulation
;; ----------------------------------------------
(noremap :n :J ":tabprevious<CR>")
(noremap :n :K ":tabnext<CR>")
;; ----------------------------------------------


;; Various commands
;; ----------------------------------------------
(noremap :c "w!!" "%!sudo tee > /dev/null %")
;; ----------------------------------------------
