# --- flake-parts/pkgs/handoff/default.nix
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
{
  lib,
  buildPythonApplication,
  setuptools,
  pytestCheckHook,
  git,
  rclone,
}:
buildPythonApplication {
  pname = "handoff";
  version = "0.1.0";
  pyproject = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./pyproject.toml
      ./README.md
      ./src
      ./tests
    ];
  };

  build-system = [ setuptools ];

  # git and rclone are called by name
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        git
        rclone
      ]
    }"
  ];

  nativeCheckInputs = [
    pytestCheckHook
    git
    rclone
  ];
  pythonImportsCheck = [ "handoff" ];

  meta = {
    description = "Carry dirty git working trees between machines through an encrypted rclone relay";
    license = lib.licenses.mit;
    mainProgram = "handoff";
    platforms = lib.platforms.linux;
  };
}
