# --- profiles/dmenu-pywaled.nix
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
{ config, pkgs, lib, inputs, user, ... }:
let
  # TODO wait for dmenu-rs fix PR to be merged
  # https://github.com/NixOS/nixpkgs/pull/223667
  _ = lib.mkOverride 500;
  dmenu-pywaled = let
    name = "dmenu_run";
    buildInputs = with pkgs; [ pywal ];
    script = pkgs.writeShellScriptBin name ''
      . "''${HOME}/.cache/wal/colors.sh"

      #${pkgs.dmenu}/bin/dmenu_run -w -nb "$color0" --nf "$color15" --sb "$color1" --sf "$color15"
      ${pkgs.dmenu}/bin/dmenu_run -nb "$color0" -nf "$color15" -sb "$color1" -sf "$color15"
    '';
  in pkgs.symlinkJoin {
    inherit name;
    # paths = [ script pkgs.dmenu-rs ] ++ buildInputs;
    paths = [ script pkgs.dmenu ] ++ buildInputs;
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
  };
in {
  home-manager.users.${user} = {
    home.packages = with pkgs; [ dmenu-pywaled ];
  };
}