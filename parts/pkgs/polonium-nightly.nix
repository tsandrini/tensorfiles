# --- parts/pkgs/polonium-nightly.nix
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
  fetchFromGitHub,
  buildNpmPackage,
  plasma-framework,
}:
# how to update:
# 1. check out the tag for the version in question
# 2. run `prefetch-npm-deps package-lock.json`
# 3. update npmDepsHash with the output of the previous step
buildNpmPackage {
  pname = "polonium";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "zeroxoneafour";
    repo = "polonium";
    rev = "8b1986547ccaa9d23f2e562f74beb26d168e0336";
    hash = "sha256-GXxR9lLCpnPJL1JZESIAygTHElzU61YJpaCXrjacivU=";
  };

  npmDepsHash = "sha256-kaT3Uyq+/JkmebakG9xQuR4Kjo7vk6BzI1/LffOj/eo=";

  dontConfigure = true;

  # the installer does a bunch of stuff that fails in our sandbox, so just build here and then we
  # manually do the install
  buildFlags = [
    "res"
    "src"
  ];

  nativeBuildInputs = [ plasma-framework ];

  dontNpmBuild = true;

  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    plasmapkg2 --install pkg --packageroot $out/share/kwin/scripts

    runHook postInstall
  '';

  meta = with lib; {
    description = "Auto-tiler that uses KWin 5.27+ tiling functionality";
    license = licenses.mit;
    maintainers = with maintainers; [ peterhoeg ];
    inherit (plasma-framework.meta) platforms;
  };
}
