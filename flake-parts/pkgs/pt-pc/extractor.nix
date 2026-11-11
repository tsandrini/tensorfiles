## pt-pc's fake-PKG extraction helper (`PT.PkgExtract`, installer/Extractor):
## reads a P.T. fake PKG with LibOrbisPkg's public fake keyset and writes
## `chunk1.psarc`, `texture.qar` and `pathid_list_ps4.bin`. Store (retail) PKGs
## are refused. The game's first-run screen runs it from `extractor/` next to
## the executable.
##
## Built like upstream's tools/ci/release.py: LibOrbisPkg.Core retargeted to
## net10.0 and patched by tools/patch_liborbis_readers.py, then the helper
## built against it (framework-dependent here, not self-contained).
##
## @param pt-pc-src flake input `pt-pc-src` (LoreanXavier/pt-pc)
## @param version pt-pc's version (CMakeLists.txt PT_VERSION)
## @returns derivation with `bin/PT.PkgExtract <pkg> <empty output dir>`
{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  python3,
  pt-pc-src,
  version,
}:
let
  liborbispkg = fetchFromGitHub {
    owner = "maxton";
    repo = "LibOrbisPkg";
    rev = "643477263b2644e0803e0f58b8726ea4e3f3b7d4"; # master, 2020-07-26
    hash = "sha256-PAltypa5MkvTQY4CsudQEYFfUCmrySgwHLLgcsWgbVY=";
  };
in
buildDotnetModule {
  pname = "pt-pc-pkg-extract";
  inherit version;
  src = pt-pc-src;

  projectFile = "installer/Extractor/Extractor.csproj";
  # NOTE: no package references anywhere; the SDK's own packs suffice
  nugetDeps = ./extractor-deps.json;
  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  nativeBuildInputs = [ python3 ];

  postPatch = ''
    cp -r --no-preserve=mode ${liborbispkg} liborbis
    substituteInPlace liborbis/LibOrbisPkg.Core/LibOrbisPkg.Core.csproj \
      --replace-fail netcoreapp3.0 net10.0 \
      --replace-fail '<LangVersion>7.3</LangVersion>' '<LangVersion>latest</LangVersion>' \
      --replace-fail '<GenerateSerializationAssemblies>Auto</GenerateSerializationAssemblies>' \
                     '<GenerateSerializationAssemblies>Off</GenerateSerializationAssemblies>'
    python3 tools/patch_liborbis_readers.py liborbis
  '';

  dotnetFlags = [ "-p:LibOrbisSource=../../liborbis" ];

  executables = [ "PT.PkgExtract" ];

  # NOTE: what the game sets before running it (src/game/first_run.cpp)
  makeWrapperArgs = [
    "--set-default"
    "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT"
    "1"
  ];

  meta = {
    description = "Extracts P.T.'s game archives from a fake PKG for pt-pc";
    homepage = "https://github.com/LoreanXavier/pt-pc";
    # NOTE: the helper is MIT, LibOrbisPkg LGPL-3.0-or-later
    license = [
      lib.licenses.mit
      lib.licenses.lgpl3Plus
    ];
    mainProgram = "PT.PkgExtract";
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.tsandrini ];
  };
}
