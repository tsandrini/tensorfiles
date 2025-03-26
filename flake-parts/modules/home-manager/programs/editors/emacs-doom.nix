# --- flake-parts/modules/home-manager/programs/editors/emacs-doom.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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
{ localFlake, inputs }:
{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    getExe
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.strings) removePrefix;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkImpermanenceEnableOption;

  cfg = config.tensorfiles.hm.programs.editors.emacs-doom;
  _ = mkOverrideAtHmModuleLevel;

  impermanenceCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence = if impermanenceCheck then config.tensorfiles.hm.system.impermanence else { };
  pathToRelative = removePrefix "${config.home.homeDirectory}/";

  emacsPkg =
    with pkgs;
    ((emacsPackagesFor emacs-unstable).emacsWithPackages (epkgs: [
      epkgs.vterm
      epkgs.ws-butler
    ]));
in
{
  options.tensorfiles.hm.programs.editors.emacs-doom = {
    enable = mkEnableOption ''
      TODO
    '';

    impermanence = {
      enable = mkImpermanenceEnableOption;
    };

    repoUrl = mkOption {
      type = types.str;
      default = "https://github.com/doomemacs/doomemacs";
      description = ''
        TODO
      '';
    };

    configRepoUrl = mkOption {
      type = types.str;
      # default = "git@github.com:tsandrini/.doom.d.git";
      default = "https://github.com/tsandrini/.doom.d.git";
      description = ''
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
        emacsPackages.ws-butler
        emacsPackages.vterm

        ## Doom dependencies
        git
        (ripgrep.override { withPCRE2 = true; })
        gnutls # for TLS connectivity

        ## Optional dependencies
        fd # faster projectile indexing
        imagemagick # for image-dired
        (mkIf (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.gpg") pinentry-emacs) # in-emacs gnupg prompts
        zstd # for undo-fu-session/undo-tree compression

        ## Module dependencies
        # :checkers spell
        (aspellWithDicts (
          ds: with ds; [
            en
            cs
            en-computers
            en-science
          ]
        ))
        # :tools editorconfig
        editorconfig-core-c # per-project style config
        # :tools lookup & :lang org +roam
        sqlite
        # :lang latex & :lang org (latex previews)
        # texlive.combined.scheme-medium
        # :lang beancount
        fava # HACK Momentarily broken on nixos-unstable
        graphviz
        nodejs

        # fonts
        emacs-all-the-icons-fonts
        nerd-fonts.symbols-only
        pandoc
        discount # Implementation of Markdown markup language in C

        dockfmt # Dockerfile format
        dockerfile-language-server-nodejs # A language server for Dockerfiles powered by Node.js, TypeScript, and VSCode technologies

        ## :lang config (json, yaml, xml)
        nodePackages.vscode-json-languageserver # JSON language server
        yaml-language-server # Language Server for YAML Files
        yamlfmt # An extensible command line tool or library to format yaml files.
        libxml2 # XML parsing library for C
        libxmlb # A library to help create and query binary XML blobs

        ## :lang php
        phpPackages.composer # Dependency Manager for PHP
        php # An HTML-embedded scripting language

        ## :lang web
        html-tidy # A HTML validator and `tidier'
        nodePackages.js-beautify # beautifier.io for node
        stylelint # Mighty CSS linter that helps you avoid errors and enforce conventions
        nodePackages.eslint

        ## :lang ansible
        ansible # Radically simple IT automation
        ansible-lint # Best practices checker for Ansible

        ## :lang ocaml
        dune_3 # A composable build system
        ocamlPackages.ocamlformat # Auto-formatter for OCaml code
        ocamlPackages.utop # Universal toplevel for OCaml
        ocamlPackages.ocp-indent # A customizable tool to indent OCaml code
        ocamlPackages.merlin # An editor-independent tool to ease the development of programs in OCaml

        ## :lang rust
        # rustc # A safe, concurrent, practical language (wrapper script)
        rustup # The Rust toolchain installer

        ## :lang sh
        shfmt # A shell parser and formatter
        shellcheck # Shell script analysis tool
        nodePackages.bash-language-server # A language server for Bash

        ## :lang haskell
        ghc
        haskell-language-server # LSP server for GHC
        haskellPackages.hoogle # Haskell API Search
        haskellPackages.cabal-install # The command-line interface for Cabal and Hackage

        ## :lang cc
        clang-tools # Standalone command line tools for C++ development
        glslang # Khronos reference front-end for GLSL and ESSL

        ## :lang csharp
        csharpier # An opinionated code formatter for C#

        ## :lang fsharp
        fsharp # A functional CLI language

        ## :lang julia
        # julia-bin

        ## :lang julia
        lua-language-server # A language server that offers Lua language support

        ## :lang go
        gopls # Official language server for the Go language
        gomodifytags # Go tool to modify struct field tags
        gotests # Generate Go tests from your source code
        gore # Yet another Go REPL that works nicely
        gotools # Additional tools for Go development

        ## :lang python
        black # The uncompromising Python code formatter
        pipenv # Python Development Workflow for Humans
        poetry # Python dependency management and packaging made easy
        (python311.withPackages (
          ps: with ps; [
            grip
            pyflakes
            isort
            pipenv
            # nose # NOTE deprecated and unsupported
            pytest
            inputs.self.packages.${system}.my_cookies
          ]
        ))
        inputs.self.packages.${system}.my_cookies
        pyright

        ## :lang zig
        zig # General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software

        ## :lang nix
        nil # Yet another language server for Nix
        #alejandra # The Uncompromising Nix Code Formatter
        statix # Lints and suggestions for the nix programming language
        deadnix # Find and remove unused code in .nix source files
        nixfmt-rfc-style # An opinionated formatter for Nix
      ];

      services.emacs = {
        enable = _ false;
        package = _ emacsPkg;
        startWithUserSession = _ "graphical";
      };

      home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

      home.activation.installDoomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d "${config.xdg.configHome}/emacs" ]; then
           ${getExe pkgs.git} clone --depth=1 --single-branch "${cfg.repoUrl}" "${config.xdg.configHome}/emacs"
        fi
        if [ ! -d "${config.xdg.configHome}/doom" ]; then
           ${getExe pkgs.git} clone "${cfg.configRepoUrl}" "${config.xdg.configHome}/doom"
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

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
