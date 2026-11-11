## pt-pc: native PC port of P.T. (2014 PS4 teaser), built from source.
##
## No game data is packaged: the game reads `chunk1.psarc`, `texture.qar` and
## `pathid_list_ps4.bin` from the player's own copy at run time. On the first
## start, the game asks for a fake PKG or a dump folder (extracting a PKG with
## the bundled `PT.PkgExtract` into the data folder) and remembers the choice in
## `game_dir.txt`; `pt-pc --game <folder>` skips the question.
##
## `bin/pt-pc` keeps settings, saves, logs and mods in
## `$PT_DATA_DIR`, default `${XDG_DATA_HOME:-~/.local/share}/pt-pc`, and never
## looks for updates (the store copy cannot update itself).
##
## @param pt-pc-src flake input `pt-pc-src` (LoreanXavier/pt-pc, a release tag)
## @returns derivation with `bin/pt-pc` and `libexec/pt-pc/` (upstream's
##   portable layout: pt, shaders/, voice/, fonts/, extras.pak, licenses/,
##   extractor/)
{
  lib,
  stdenv,
  callPackage,
  cmake,
  ninja,
  shaderc,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  icoutils,
  vulkan-headers,
  vulkan-loader,
  sdl3,
  # flake input `pt-pc-src` (LoreanXavier/pt-pc)
  pt-pc-src,
}:
let
  version = lib.head (
    builtins.match ''.*set\(PT_VERSION "([0-9.]+)"\).*'' (
      builtins.readFile "${pt-pc-src}/CMakeLists.txt"
    )
  );
  deps = callPackage ./deps.nix { };
  # NOTE: the data-free unit tests of upstream's tools/linux/run_tests.sh
  # (pt_platform_test without --network, pt_save_reset_test in checkPhase);
  # pt_peephole_look_test is left out, it needs the game folder (exit 2)
  unitTests = [
    "pt_platform_test"
    "pt_tests"
    "pt_collision_test"
    "pt_mods_test"
    "pt_graphics_preset_test"
    "pt_gouge_input_test"
    "pt_light_cull_test"
  ];
  extractor = callPackage ./extractor.nix { inherit pt-pc-src version; };
in
stdenv.mkDerivation {
  pname = "pt-pc";
  inherit version;
  src = pt-pc-src;

  patches = [
    ./data-dir.patch
    ./gcc-metalfx-stub.patch
  ];

  postPatch = ''
    ${lib.concatStrings (
      lib.mapAttrsToList (name: dep: ''
        grep -qF ${lib.escapeShellArg dep.pin} cmake/Dependencies.cmake || {
          echo "pt-pc: cmake/Dependencies.cmake no longer pins ${name} (${dep.pin}); update deps.nix" >&2
          exit 1
        }
      '') deps.sources
    )}

    # NOTE: nixpkgs' shared SDL3 instead of a static FetchContent build: it
    # carries the run-time paths of the libraries SDL dlopens (Wayland, X11,
    # PipeWire, PulseAudio, ALSA, udev)
    substituteInPlace cmake/Dependencies.cmake \
      --replace-fail 'FetchContent_MakeAvailable(sdl3 zlib)' \
                     'find_package(SDL3 REQUIRED CONFIG)
    FetchContent_MakeAvailable(zlib)' \
      --replace-fail SDL3::SDL3-static SDL3::SDL3
    substituteInPlace CMakeLists.txt --replace-fail SDL3::SDL3-static SDL3::SDL3

    # NOTE: no .git here; the id goes into pt.log and crash reports
    substituteInPlace cmake/build_id.cmake --replace-fail 'set(id "dev")' 'set(id "${pt-pc-src.shortRev}")'
  '';

  nativeBuildInputs = [
    cmake
    ninja
    shaderc # glslc
    makeWrapper
    copyDesktopItems
    icoutils
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    sdl3
  ];

  # NOTE: upstream's release build type
  cmakeBuildType = "RelWithDebInfo";

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    # NOTE: Linux FSR 3.1 needs AMD's Windows shader compiler (through wine),
    # DLSS an NVIDIA GPU; VR is experimental and Windows-only by default
    (lib.cmakeBool "PT_UPSCALERS" false)
    (lib.cmakeBool "PT_OPENXR" false)
  ]
  ++ lib.mapAttrsToList (
    name: dep: lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_${lib.toUpper name}" "${dep.src}"
  ) deps.sources;

  # NOTE: CMake skips its downloads when these are in place with the right hash
  preConfigure = ''
    mkdir -p build/voice build/_deps/ww2ogg
    ${lib.concatStrings (
      lib.mapAttrsToList (name: model: ''
        ln -s ${model} build/voice/${name}
      '') deps.voiceModels
    )}
    cp ${deps.wwiseCodebooks} build/_deps/ww2ogg/packed_codebooks_aoTuV_603.bin
  '';

  # NOTE: pt_release is what releases ship as `pt` (loop browser locked until
  # the game was finished once); `pt` stages fonts/ and licenses/ beside it
  ninjaFlags = [
    "pt"
    "pt_release"
    "pt_save_reset_test"
  ]
  ++ unitTests;

  doCheck = true;
  checkPhase = ''
    runHook preCheck

    for t in ${lib.concatStringsSep " " unitTests}; do
      echo "check: $t"
      ./$t
    done
    echo "check: pt_save_reset_test"
    ./pt_save_reset_test "$TMPDIR/save-reset"

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    dir=$out/libexec/pt-pc
    install -Dm0755 pt_release $dir/pt
    install -Dm0644 shaders/*.spv -t $dir/shaders
    install -Dm0644 extras.pak -t $dir
    cp -r fonts licenses $dir/

    install -Dm0755 voice/lib*.so -t $dir/voice
    cp -r voice/licenses $dir/voice/
    ${lib.concatStrings (
      lib.mapAttrsToList (name: model: ''
        ln -s ${model} $dir/voice/${name}
      '') deps.voiceModels
    )}
    # NOTE: the build RPATH points into the build tree; the libraries find
    # each other next to themselves
    for so in $dir/voice/lib*.so; do
      patchelf --set-rpath '$ORIGIN' "$so"
    done

    mkdir -p $dir/extractor
    ln -s ${lib.getExe extractor} $dir/extractor/PT.PkgExtract

    install -Dm0644 $src/README.md $src/docs/*.md -t $out/share/doc/pt-pc

    for size in 16 24 32 48 64 96 128 256; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      icotool -x -w $size -o $out/share/icons/hicolor/''${size}x''${size}/apps/pt-pc.png $src/assets/pt.ico
    done

    # NOTE: settings, saves, logs and mods outside the store; the store copy
    # cannot update itself
    makeWrapper $dir/pt $out/bin/pt-pc \
      --run 'export PT_DATA_DIR="''${PT_DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/pt-pc}"' \
      --add-flags --no-update-check

    runHook postInstall
  '';

  # NOTE: volk dlopens the Vulkan loader; after fixup, which would shrink it away
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath [ vulkan-loader ]} $out/libexec/pt-pc/pt
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "pt-pc";
      desktopName = "P.T.";
      comment = "Native PC port of P.T.";
      exec = "pt-pc";
      icon = "pt-pc";
      categories = [ "Game" ];
    })
  ];

  passthru = { inherit extractor deps; };

  meta = {
    description = "Native PC port of P.T., running from your own PS4 game files";
    homepage = "https://github.com/LoreanXavier/pt-pc";
    license = lib.licenses.mit;
    mainProgram = "pt-pc";
    # NOTE: the voice recognizer's ggml CPU variants are x86-64 ones
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.tsandrini ];
  };
}
