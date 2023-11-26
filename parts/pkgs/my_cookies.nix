# --- parts/pkgs/my_cookies.nix
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
    pname = "my_cookies";
    version = "0.1.3";

    src = fetchPypi {
      inherit pname version;
      sha256 = "ddee63d0714e5d4c94a3a61550a4276dac6f014b43a114f31aa5bc1d47f3ad0f";
    };

    propagatedBuildInputs = [setuptools browser-cookie3];

    # No tests included
    doCheck = false;
    pythonImportsCheck = ["my_cookies"];

    meta = with lib; {
      homepage = "https://github.com/kaiwk/my_cookies";
      description = "This package is used for retrieve leetcode cookies from Chrome with local keyring.";
      license = licenses.mit;
      maintainers = with tensorfiles.maintainers; [tsandrini];
    };
  }
