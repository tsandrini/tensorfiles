# --- flake-parts/pkgs/awatcher.nix
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
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "awatcher";
  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "2e3s";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-e65QDbK55q1Pbv/i7bDYRY78jgEUD1q6TLdKD8Gkswk=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  # NOTE needed due to Cargo.lock containing git dependencies
  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "aw-client-rust-0.1.0" = "sha256-fCjVfmjrwMSa8MFgnC8n5jPzdaqSmNNdMRaYHNbs8Bo=";
    };
  };

  meta = with lib; {
    description = "Awatcher is a window activity and idle watcher for ActivityWatcher with an optional tray and UI for statistics.";
    homepage = "https://github.com/2e3s/awatcher";
    changelog = "https://github.com/2e3s/awatcher/releases/tag/${version}";
    license = licenses.mpl20;
    maintainers = with tensorfiles.maintainers; [ tsandrini ];
    platforms = platforms.linux;
    mainProgram = pname;
  };
}
