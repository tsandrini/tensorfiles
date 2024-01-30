# --- parts/modules/home-manager/programs/editors/emacs-doom.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
{
  config,
  lib,
  pkgs,
  self,
  inputs,
  system,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.editors.emacs-doom;
  _ = mkOverride 700;

  impermanenceCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence")
    && cfg.impermanence.enable;
  impermanence =
    if impermanenceCheck
    then config.tensorfiles.hm.system.impermanence
    else {};
  pathToRelative = strings.removePrefix "${config.home.homeDirectory}/";

  emacsPkg = with pkgs; ((emacsPackagesFor emacs-unstable).emacsWithPackages
    (epkgs: [epkgs.vterm]));
in {
  options.tensorfiles.hm.programs.editors.emacs-doom = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    impermanence = {enable = mkImpermanenceEnableOption;};

    repoUrl = mkOption {
      type = str;
      default = "https://github.com/doomemacs/doomemacs";
      description = mdDoc ''
        TODO
      '';
    };

    configRepoUrl = mkOption {
      type = str;
      # default = "git@github.com:tsandrini/.doom.d.git";
      default = "https://github.com/tsandrini/.doom.d.git";
      description = mdDoc ''
        TODO
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = with pkgs; [
        ## Emacs itself
        binutils # native-comp needs 'as', provided by this
        # 28.2 + native-comp
        emacsPkg

        ## Doom dependencies
        git
        (ripgrep.override {withPCRE2 = true;})
        gnutls # for TLS connectivity

        ## Optional dependencies
        fd # faster projectile indexing
        imagemagick # for image-dired
        # (mkIf (config.programs.gnupg.agent.enable) # TODO
        #   pinentry_emacs) # in-emacs gnupg prompts
        zstd # for undo-fu-session/undo-tree compression

        ## Module dependencies
        # :checkers spell
        (aspellWithDicts (ds: with ds; [en cs en-computers en-science]))
        # :tools editorconfig
        editorconfig-core-c # per-project style config
        # :tools lookup & :lang org +roam
        sqlite
        # :lang latex & :lang org (latex previews)
        texlive.combined.scheme-medium
        # :lang beancount
        fava # HACK Momentarily broken on nixos-unstable
        nodejs-slim
        graphviz

        # fonts
        emacs-all-the-icons-fonts
        (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
        (python311.withPackages (ps:
          with ps; [
            grip
            pyflakes
            isort
            pipenv
            nose
            pytest
            inputs.self.packages.${system}.my_cookies
          ]))
        inputs.self.packages.${system}.my_cookies
        pandoc
        discount # Implementation of Markdown markup language in C

        # default Language packages: linters, formatters, LSPs, etc...
        shellcheck # Shell script analysis tool
        ansible # Radically simple IT automation
        ansible-lint # Best practices checker for Ansible
        clang-tools # Standalone command line tools for C++ development
        shfmt
        libxml2 # XML parsing library for C
        libxmlb # A library to help create and query binary XML blobs
        haskell-language-server # LSP server for GHC
        haskellPackages.hoogle # Haskell API Search
        haskellPackages.cabal-install # The command-line interface for Cabal and Hackage
        #nixfmt # An opinionated formatter for Nix
        ocamlPackages.ocamlformat # Auto-formatter for OCaml code
        dune_3 # A composable build system
        ocamlPackages.utop # Universal toplevel for OCaml
        ocamlPackages.ocp-indent # A customizable tool to indent OCaml code
        ocamlPackages.merlin # An editor-independent tool to ease the development of programs in OCaml
        phpPackages.composer # Dependency Manager for PHP
        php # An HTML-embedded scripting language
        black # The uncompromising Python code formatter
        pipenv # Python Development Workflow for Humans
        rust-analyzer # A modular compiler frontend for the Rust language
        cargo # Downloads your Rust project's dependencies and builds your project
        rustc # A safe, concurrent, practical language (wrapper script)
        stylelint # Mighty CSS linter that helps you avoid errors and enforce conventions
        nodePackages.js-beautify # beautifier.io for node
        yaml-language-server # Language Server for YAML Files
        yamlfmt # An extensible command line tool or library to format yaml files.
        nodePackages.bash-language-server # A language server for Bash
        dockfmt # Dockerfile format
        html-tidy # A HTML validator and `tidier'

        nil # Yet another language server for Nix
        alejandra # The Uncompromising Nix Code Formatter
        statix # Lints and suggestions for the nix programming language
        deadnix # Find and remove unused code in .nix source files
      ];

      services.emacs = {
        enable = _ true;
        package = emacsPkg;
        startWithUserSession = _ "graphical";
      };

      home.sessionPath = ["${config.xdg.configHome}/emacs/bin"];

      home.activation.installDoomEmacs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d "${config.xdg.configHome}/emacs" ]; then
           ${
          getExe pkgs.git
        } clone --depth=1 --single-branch "${cfg.repoUrl}" "${config.xdg.configHome}/emacs"
        fi
        if [ ! -d "${config.xdg.configHome}/doom" ]; then
           ${
          getExe pkgs.git
        } clone "${cfg.configRepoUrl}" "${config.xdg.configHome}/doom"
        fi
      '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        directories = [
          (pathToRelative "${config.xdg.configHome}/emacs")
          (pathToRelative "${config.xdg.configHome}/doom")
        ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);
}
