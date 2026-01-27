# --- flake-parts/pkgs/certbot-dns-wedos.nix
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
{ lib, python3, ... }:
with python3.pkgs;
buildPythonPackage rec {
  pname = "certbot-dns-wedos";
  version = "2.4";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "certbot_dns_wedos";
    hash = "sha256-Sle3hoBLwVPF30caCyYtt3raY5Gs9ekg0DthvHxvB4E=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    certbot
    acme
    requests
    pytz
  ];

  pythonImportsCheck = [ "certbot_dns_wedos" ];

  meta = {
    homepage = "https://github.com/clazzor/certbot-dns-wedos";
    description = " Certbot plugin for authentication using Wedos plugin ";
    license = lib.licenses.apsl20;
    maintainers = [ lib.maintainers.tsandrini ];
  };
}
