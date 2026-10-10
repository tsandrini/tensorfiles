{
  lib,
  rustPlatform,
  runCommand,
  pkg-config,
  installShellFiles,
  wayland,
  systemdLibs,
  pipewire,
  libgbm,
  libglvnd,
  seatd,
  libinput,
  libxkbcommon,
  libdisplay-info_0_3,
  pango,
  shaderc,
  vulkan-loader,
  # flake inputs `niri-spicy-src` / `smithay-spicy-src` (losnoco spicy branches)
  niri-src,
  smithay-src,
}:
let
  # NOTE: niri's Cargo.toml `[patch]`es smithay to `path = "../smithay"`, so
  # the two trees have to be siblings in the build directory.
  src = runCommand "niri-spicy-src" { } ''
    mkdir -p $out
    cp -r ${niri-src} $out/niri
    cp -r ${smithay-src} $out/smithay
  '';

  # NOTE: 26.4.0 = the upstream niri the branch is based on (Cargo.toml)
  date = niri-src.lastModifiedDate;
  version = "26.4.0-unstable-${lib.substring 0 4 date}-${lib.substring 4 2 date}-${lib.substring 6 2 date}-${niri-src.shortRev}";
in
rustPlatform.buildRustPackage {
  pname = "niri-spicy";
  inherit version src;
  sourceRoot = "${src.name}/niri";

  cargoLock = {
    lockFile = "${niri-src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    installShellFiles
  ];

  buildInputs = [
    wayland
    libgbm
    libglvnd
    seatd
    libinput
    libdisplay-info_0_3
    libxkbcommon
    pango
    pipewire
    systemdLibs
    shaderc
    vulkan-loader
  ];

  # NOTE: smithay's `renderer_vulkan` pulls in shaderc-sys; link the system
  # library instead of building shaderc from source
  SHADERC_LIB_DIR = "${lib.getLib shaderc}/lib";

  buildNoDefaultFeatures = true;
  buildFeatures = [
    "dbus"
    "xdp-gnome-screencast"
    "systemd"
  ];

  # NOTE: the test suite spins up a real compositor with a mock backend and
  # needs a runtime dir; the egl tests need a GPU
  preCheck = ''
    export XDG_RUNTIME_DIR="$(mktemp -d)"
  '';
  checkFlags = [ "--skip=::egl" ];

  passthru.providedSessions = [ "niri" ];

  # readable backtraces
  dontStrip = true;
  RUSTFLAGS = [
    "-C link-arg=-Wl,--push-state,--no-as-needed"
    "-C link-arg=-lEGL"
    "-C link-arg=-lwayland-client"
    "-C link-arg=-Wl,--pop-state"
    "-C debuginfo=line-tables-only"
  ];
  NIRI_BUILD_VERSION_STRING = "spicy ${version} (commit ${niri-src.rev})";

  outputs = [
    "out"
    "doc"
  ];

  postPatch = ''
    export RUSTFLAGS="$RUSTFLAGS --remap-path-prefix $NIX_BUILD_TOP=/"
    export RUSTFLAGS="$RUSTFLAGS --remap-path-prefix $NIX_BUILD_TOP/${src.name}/niri=./"

    patchShebangs resources/niri-session
  '';

  postInstall = ''
    install -Dm0755 resources/niri-session -t $out/bin
    install -Dm0644 resources/niri.desktop -t $out/share/wayland-sessions
    install -Dm0644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
    install -Dm0644 resources/niri{-shutdown.target,.service} -t $out/lib/systemd/user

    installShellCompletion --cmd niri \
      --bash <($out/bin/niri completions bash) \
      --zsh <($out/bin/niri completions zsh) \
      --fish <($out/bin/niri completions fish) \
      --nushell <($out/bin/niri completions nushell)

    install -Dm0644 README.md resources/default-config.kdl -t $doc/share/doc/niri
    mv docs/wiki $doc/share/doc/niri/wiki
  '';

  postFixup = ''
    substituteInPlace $out/lib/systemd/user/niri.service \
      --replace-fail "ExecStart=niri" "ExecStart=$out/bin/niri"
  '';

  meta = {
    description = "niri with the community HDR / color-management / Vulkan feature branches (niri-spicy)";
    homepage = "https://github.com/losnoco/niri/tree/spicy-main";
    license = lib.licenses.gpl3Only;
    mainProgram = "niri";
    platforms = lib.platforms.linux;
  };
}
