{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  python3,
  vulkan-headers,
  vulkan-loader,
  sdl3,
  ffmpeg,
  curl,
  zlib,
  spirv-tools,
  # flake input `bbhost-src` (droogie/bbhost master)
  bbhost-src,
}:
let
  date = bbhost-src.lastModifiedDate;
  version = "0-unstable-${lib.substring 0 4 date}-${lib.substring 4 2 date}-${lib.substring 6 2 date}-${bbhost-src.shortRev}";
in
stdenv.mkDerivation {
  pname = "bbhost";
  inherit version;
  src = bbhost-src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3 # tests only
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    sdl3
    ffmpeg
    curl
    zlib
    spirv-tools
  ];

  # NOTE: upstream's release build type; the decomp sources must match the
  # game's floating point bit for bit
  cmakeBuildType = "RelWithDebInfo";

  # NOTE: cmake/version.cmake shells out to git, absent here; without tags the
  # binary reports itself as `v0.0.0-<rev>`
  env.BBHOST_GIT_REV = bbhost-src.shortRev;

  # NOTE: tests that need the game files exit 77 and are reported as skipped
  doCheck = true;

  # NOTE: bbhost resolves `plugins/` and `patches/` beside its real path
  # (/proc/self/exe), so `bin/bbhost` can stay a plain symlink
  installPhase = ''
    runHook preInstall

    install -Dm0755 bbhost -t $out/libexec/bbhost
    install -Dm0755 plugins/{randomizer,boss_rush,mutators,debug_menu}.so -t $out/libexec/bbhost/plugins
    cp -r $src/patches $out/libexec/bbhost/patches
    install -Dm0644 $src/bbhost.example.toml $src/docs/*.md -t $out/share/doc/bbhost

    mkdir -p $out/bin
    ln -s ../libexec/bbhost/bbhost $out/bin/bbhost

    runHook postInstall
  '';

  meta = {
    description = "Translation layer running Bloodborne's 1.09 PS4 executable natively on Linux via Vulkan";
    homepage = "https://github.com/droogie/bbhost";
    license = lib.licenses.gpl3Plus;
    mainProgram = "bbhost";
    # NOTE: runs the game's x86-64 code natively
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.tsandrini ];
  };
}
