(module dotfiles.core
  {require {nvim aniseed.nvim}
   require-macros [dotfiles.macros]})


;; Colors/GUI
;; ----------------------------------------------
(execstr "colorscheme wal")
;(nvim.ex.set "background=light")
;(_: "colorscheme default")
;(set nvim.o.termguicolors false)
;(set nvim.o.mouse "a")
;; ----------------------------------------------


;; General setup
;; ----------------------------------------------
(nvim.ex.set :number)
(nvim.ex.set :relativenumber)

(nvim.ex.set "formatoptions+=l")
(nvim.ex.set "rulerformat=%l:%c")
(nvim.ex.set :nofoldenable)
(nvim.ex.set "clipboard=unnamedplus")

(nvim.ex.set :wildmenu)
(nvim.ex.set "wildmode=full")
(nvim.ex.set :wildignorecase)

(nvim.ex.set "tabstop=8")
(nvim.ex.set "softtabstop=0")
(nvim.ex.set :expandtab)
(nvim.ex.set "shiftwidth=4")
(nvim.ex.set :smarttab)

(nvim.ex.set "scrolloff=5")

(nvim.ex.set :list)
(nvim.ex.set "listchars=tab:›\\ ,trail:•,extends:#,nbsp:.")

(execstr "filetype indent on")
(nvim.ex.set :smartindent)
(nvim.ex.set :shiftround)

(nvim.ex.set :smartcase)
(nvim.ex.set :showmatch)
;; ----------------------------------------------


;; Autocommands
;; ----------------------------------------------
(augroup on_save_trim_whitespace
    (autocmd :BufWritePre :* ":%s/\\s\\+$//e"))
;; ----------------------------------------------
