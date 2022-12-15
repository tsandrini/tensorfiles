(module dotfiles.plugins
  {autoload {nvim aniseed.nvim
             a aniseed.core
             util dotfiles.util
             packer packer}})

(defn safe-require-plugin-config [name]
  (let [(ok? val-or-err) (pcall require (.. :dotfiles.plugins. name))]
    (when (not ok?)
      (print (.. "dotfiles error: " val-or-err)))))

(defn- use [...]
  "Iterates through the arguments as pairs and calls packer's use function for
  each of them. Works around Fennel not liking mixed associative and sequential
  tables as well."
  (let [pkgs [...]]
    (packer.startup
      (fn [use]
        (for [i 1 (a.count pkgs) 2]
          (let [name (. pkgs i)
                opts (. pkgs (+ i 1))]
            (-?> (. opts :mod) (safe-require-plugin-config))
            (use (a.assoc opts 1 name))))))))

;; Plugins to be managed by packer.
(use
  :Olical/aniseed {}
  :Olical/conjure {}
  :Olical/nvim-local-fennel {}
  :tpope/vim-repeat {}
  :kyazdani42/nvim-web-devicons {}
  :nvim-treesitter/nvim-treesitter {:mod :treesitter}
  ;:neovim/nvim-lspconfig {}
  ;:glepnir/lspsaga.nvim {:mod :lspsaga}
  ;:folke/trouble.nvim {:mod :trouble}
  :mcchrish/nnn.vim {:mod :nnn}
  :tpope/vim-fugitive {}
  ;:rhysd/git-messenger.vim {}
  :tpope/vim-surround {}
  :Yggdroot/indentLine {:mod :indentline}
  :cohama/lexima.vim {}
  :hrsh7th/vim-vsnip {:mod :vsnip}
  :hrsh7th/vim-vsnip-integ {}
  ;; :nvim-lua/completion-nvim {:mod :completion}
  ;; :nvim-treesitter/completion-treesitter {}
  ;; :kristijanhusak/completion-tags {}
  :rafamadriz/friendly-snippets {}
  :matze/vim-move {:mod :move}
  :lambdalisue/fern.vim {:mod :fern}
  :lambdalisue/glyph-palette.vim {}
  :lambdalisue/nerdfont.vim {}
  :lambdalisue/fern-git-status.vim {}
  :nvim-lua/popup.nvim {}
  :nvim-lua/plenary.nvim {}
  :nvim-telescope/telescope.nvim {:mod :telescope}
  :lambdalisue/fern-renderer-nerdfont.vim {}
  :easymotion/vim-easymotion {:mod :easymotion}
  :jlanzarotta/bufexplorer {}
  :mbbill/undotree {}
  :folke/which-key.nvim {:mod :whichkeynvim}
  ;; :liuchengxu/vim-which-key {}
  ;; :AckslD/nvim-whichkey-setup.lua {:mod :whichkey}
  :hoob3rt/lualine.nvim {:mod :lualine}
  :dylanaraps/wal.vim {}
  ;:glepnir/dashboard-nvim {:mod :dashboard}
  :wbthomason/packer.nvim {}
  )
