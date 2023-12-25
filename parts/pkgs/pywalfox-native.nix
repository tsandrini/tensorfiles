# --- parts/pkgs/pywalfox-native.nix
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
  python3,
  ...
}:
with python3.pkgs;
  buildPythonApplication rec {
    pname = "pywalfox";
    version = "2.7.4";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Wec9fic4lXT7gBY04D2EcfCb/gYoZcrYA/aMRWaA7WY=";
    };

    propagatedBuildInputs = [setuptools];

    # No tests included
    doCheck = false;
    pythonImportsCheck = ["pywalfox"];

    meta = with lib; {
      homepage = "https://github.com/Frewacom/pywalfox-native";
      description = "Native app used alongside the Pywalfox addon.";
      license = licenses.mpl20;
      maintainers = with tensorfiles.maintainers; [tsandrini];
    };
  }
