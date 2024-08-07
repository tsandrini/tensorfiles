<!-- markdownlint-disable MD024 -->

# Changelog

## v0.4.0 (2024-08-06)

### Feat

- **hosts**: switch armcord -> vesktop
- **spinorbundle**: remove spicetify
- **jetbundle**: add manuals
- **hosts**: enable nh gc instead of default
- **nh**: add nh module
- **packages-extra**: add nix-fast-build
- **packages-extra**: add gitu & commitizen to global scope
- **flake**: update inputs
- **hosts**: clean up some unused programs
- **zsh**: add ripgrep list-todos alias
- **git**: add various QL git aliases
- **activitywatch**: init activitywatch, add aw to firefox & hosts
- **topology-nix**: init topology graph gen
- **flake**: update inputs
- **hosts**: disable custom pywaflox and use nixpkgs version
- **zsh**: increase history size
- **polonium-nightly**: update
- **kdeplasma**: update kde settings
- **firefox**: add refined-github plugin
- **texlive**: medium -> full
- **neovim**: add ignorecase
- **flake**: update inputs
- **neovim**: add vscode setup
- **packages-extra**: add nix-alien
- **wireguard-&-btrfs**: add wg and update btrfs settings
- **wireguard**: disable firewall for networkmanager
- **neovim**: fix pywal conditional & update user groups
- **hm-tmux**: init and configure tmux
- **hm-neovim**: add pywal conditional
- **hm-zsh**: update history
- **polonium-nightly**: update
- **polonium-nightly**: update
- **polonium-nightly**: update
- **flake**: update project template
- **polonium-nightly**: update version
- **devenv**: update version
- **emacs-doom**: update lsp dependencies
- **polonium-nightly**: bump version
- **jetbundle**: add fingerprint reader sw mappings
- **polonium-nightly**: bump version
- **emacs-doom**: enable emacs service
- **emacs-doom**: updates
- **packages**: update pgadmin, adminer
- **polonium-nightly**: update version
- **flake**: update inputs
- **autoupgrade**: disable
- **spinorbundle**: switch to plasma6
- **rc2nix**: update current plasma6 config
- **plasma6**: init plasma6 modules
- **firefox**: sync bookmarks, temporarily allow cookies & sessions
- **flake**: update inputs
- **devshell**: switch to nixpkgs package version instead
- **firefox**: treestyle-tab -> sidebery
- **emacs-doom**: add LSP & gpg packages
- **hm-firefox**: add treestyle tab & other addons
- **spinorbundle**: add osu-stable to host
- **spinorbundle**: update host
- **emacs-doom**: update emacs language dependencies
- **polonium**: update source to v1.0
- **project**: update
- **hosts**: add hardware tweaks
- **hosts**: add various kdepackages, tabletdrivers, etc
- **kdeplasma**: update
- **plasma**: update
- **jetbundle**: update
- **jetbundle**: add jetbundle host
- **plasma**: update
- **plasma**: update
- **plasma**: update
- **locales**: update
- **plasma**: update
- **plasma**: update
- **plasma**: update
- **plasma**: update
- **plasma**: update
- **plasma**: update
- **plasma**: remove gtk dep
- **plasma**: update
- **plasma**: update
- **plasma**: update
- **kdeplasma**: init
- **shadow-tech**: add shadow-nix nixos module
- **impermanence**: add various cache directories
- **nixos,hm**: move nixos module to hm & add xmonad hm
- **homeModules**: add yazi module
- **home**: fix leetcode.el, add lf and btop modules
- **home**: add ssh,redshift, doomemacs and alacritty modules
- **flake**: update flake inputs
- **home**: add firefox, git, ssh, agenix, pywalfox hm modules
- **homes**: add picom, redshift, dunst, gtk
- **homes**: remove old dotfiles, migrate additional nix modules to hm
- **project**: decouple project structure into parts & add hm modules
- **modules**: decouple nixos,home-manager modules
- **project**: decouple individual outputs into modules
- **hyprland**: add ags,anyrun,base config
- **hyprland**: add getUserGraphicalBackend helper, hyprland TODO list
- **wayland**: rewire packages to use wayland binary cache
- **flake**: add additional binary caches
- **flake**: add viperML/nh tool, update gitignore
- **flake**: rewire project to use flake-parts, add treefmt
- **flake**: add flake-parts
- **ci**: update ci to use devenv check
- **hyprland**: separate hyprland into a module, add waybar
- **hyprland**: update
- **project**: add commitizen with proper semantic versioning
- **modules,lib**: add direnv module,add additional lib helpers
- **devenv**: update devenv with devcontainers and other features

### Fix

- **firefox**: fix wiping of history
- **gitignore**: fix tsandrini entry
- **flake**: post rewrite tweaks
- **emacs-doom**: remove rustc, use rustup
- **awatcher**: fix systemd unit definition
- **nixos-headless**: remove unused passed argument inputs
- **tsandrini@jetbundle**: update package list
- **emacs-doom**: fix pinentry-emacs package rename
- **system-autoupgrade**: remove channel option
- **README**: add missing example image
- **jetbundle**: fixes
- **plasma**: partitionmanager fix
- **plasma**: partitionmanager fix
- **plasma**: migrate from 6 to 5
- **spinorbundle**: plasma init
- **shadow-nix**: xsession typo
- **hm-zsh**: fix
- **hm-zsh**: fix
- **hm-zsh**: fix impermanence
- **hm-pywal**: g s
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-headless**: fix
- **hm-firefox**: enable fix
- **headless**: impermanence fix
- **hm-headless**: test
- **headless**: remove blank inits
- **zsh**: fix impermanence option
- **doom**: fix unbound varialbe
- **spinorbundle**: fix zsh
- **spinorbundle**: zsh enable
- **spinorbundle**: set default user shell
- **hm-headless**: fix impermanece persistentroot
- **agenix**: fix impermanence agenix option definition
- **agenix**: fix host ssh key path
- **agenix**: fix identities loading stategy
- **project**: fixed all of the various bugs due to reformat
- **doom-emacs**: fix overlay package
- **hyprland**: fix code typo
- **ags**: fix ags init
- **wayland**: hyprland, waybar fixes
- **modules.system.users**: fix allowed users setting

### Refactor

- **flake**: update CI & remove impurities
- **flake**: rewrite -> flake-parts-builder
- **emacs-doom**: disable emacs service
- **codeformat**: replace alejandra with nixfmt-rfc-style
- **plasma**: rename plasma to plasma5 to prevent conflicts
- **hosts/homes**: clean specialArgs and reduce global module context
- **hm-modules**: localize module dependencies
- **nixos-modules**: localize module scope
- **strongswan**: update vpn ipsec settings
- **modules**: simplify modules and remove external deps
- **spinorbundle**: test
- **project**: major refactor into parts
- **homes**: rename jetbundle@tsandrini
- **pkgs**: switch to hash SRI format
- **template**: update project template
- **dotfiles**: clean out old dotfiles
- **dotfiles**: update & clean old dotfiles
- **project**: move all modules to parts dir
- **hyprland**: refactor hyprland, ags and additional programs, services
- **spinorbundle**: test commit
- **project**: merge with main
- **spinorbundle**: enable hyprland

## v0.3.0 (2023-11-11)

### Feat

- **modules,lib**: add direnv module,add additional lib helpers
- **devenv**: update devenv with devcontainers and other features

### Fix

- **modules.system.users**: fix allowed users setting

## v0.2.0 (2017-02-13)

## v0.1.0 (2017-02-13)
