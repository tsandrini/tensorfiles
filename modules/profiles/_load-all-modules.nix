# --- modules/profiles/_load-all-modules.nix
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
  lib,
  inputs,
  ...
}:
with builtins;
with lib; {
  # the purpose of this module is to load all of the defined modules as well
  # as any possibly needed 3rd party modules.
  #
  # note: contrary to usual practices in imperative languages this is actually
  # the preferred way of handling dependencies between modules since
  #
  # 1. nix is a lazily evaluated language
  # 2. modules are executed only after enabling them via their options (modules
  #    that are autoenabled by default will be either turned off or simply skipped)
  #
  # by doing this, we can create a fully (mostly) importless module ecosystem
  # which prevents any potential conflicts since everything will be reduced
  # to overriding attrsets.
  imports =
    (with inputs; [
      impermanence.nixosModules.impermanence
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      nur.nixosModules.nur
    ])
    ++ (with inputs.self.nixosModules; [
      misc.gtk
      misc.nix
      misc.xdg

      programs.browsers.firefox
      programs.dmenu
      programs.editors.neovim
      programs.file-managers.lf
      programs.git
      programs.newsboat
      programs.pywal
      programs.shells.zsh
      programs.terminals.alacritty
      programs.terminals.kitty

      security.agenix

      services.dunst
      services.networking.networkmanager
      services.networking.openssh
      services.pywalfox-native
      services.x11.picom
      services.x11.redshift
      services.x11.window-managers.xmonad

      system.persistence
      system.users

      tasks.nix-garbage-collect
      tasks.system-autoupgrade

      # profiles
      profiles.base
      profiles.headless
      profiles.minimal
      profiles.laptop
    ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
