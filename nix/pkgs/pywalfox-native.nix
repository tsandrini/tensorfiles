# --- pkgs/pywalfox-native.nix
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
  pkgs,
  lib,
  # Whether the mozilla manifest should be installed globally or
  # in the target user home directory.
  # Since in NixOS mostly everything is global (`root` based) by default
  # and also because without using home-manager it doesn't integrate very well
  # with per-user configuration the default value is true
  global ? true
}:

with pkgs.python3.pkgs;
buildPythonApplication rec {
  pname = "pywalfox";
  version = "2.7.4 ";

  src = fetchPypi {
    inherit pname version;
    sha256 = "59e73d7e27389574fb801634e03d8471f09bfe062865cad803f68c456680ed66";
  };

  # No tests included
  doCheck = false;
  pythonImportsCheck = [ "pywalfox" ];

  # TODO: the manifest file is going to get deleted by the opt in fs
  #
  # `pywalfox install does 2 things`
  # 0. (optional) remove existing manifest
  # 1. copy_manifest
  #   This copies the mozilla manifest file into its target location which is
  #   either one of
  #     - /usr/lib/mozilla/native-messaging-hosts
  #     - .mozilla/native-messaging-hosts
  #
  postPatch = ''
    python3 pywalfox install ${if global then "--global" else ""}
  '';

  meta = with lib; {
    homepage    = "https://github.com/Frewacom/pywalfox-native";
    description = "Native app used alongside the Pywalfox addon.";
    license     = licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
