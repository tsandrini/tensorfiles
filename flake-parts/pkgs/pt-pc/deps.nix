## FetchContent sources and downloads of pt-pc's `cmake/Dependencies.cmake`,
## pinned to upstream's tags and SHA-256s for the offline build.
##
## Each `sources.<name>` becomes `FETCHCONTENT_SOURCE_DIR_<NAME>`; its `pin` is
## the text that `cmake/Dependencies.cmake` must still contain, so an upstream
## dependency bump fails the build instead of building against the old source.
## SDL3 is absent on purpose: the package uses nixpkgs' shared SDL3.
##
## @param fetchFromGitHub nixpkgs fetcher
## @param fetchzip nixpkgs fetcher
## @param fetchurl nixpkgs fetcher
## @returns { sources, voiceModels, wwiseCodebooks }
{
  fetchFromGitHub,
  fetchzip,
  fetchurl,
}:
let
  github =
    { pin, ... }@args:
    {
      inherit pin;
      src = fetchFromGitHub (removeAttrs args [ "pin" ]);
    };
  # NOTE: upstream pins these by the tarball's SHA-256, which is their `pin`
  tarball =
    { pin, ... }@args:
    {
      inherit pin;
      src = fetchzip (removeAttrs args [ "pin" ]);
    };
in
{
  sources = {
    zlib = github {
      pin = "madler/zlib.git GIT_TAG v1.3.2";
      owner = "madler";
      repo = "zlib";
      rev = "v1.3.2";
      hash = "sha256-Sthd9RsydSLaITNlBp6g1X35WKZdS4h7gr0QhRqdGoI=";
    };
    volk = github {
      pin = "zeux/volk.git GIT_TAG 1.4.350";
      owner = "zeux";
      repo = "volk";
      rev = "1.4.350";
      hash = "sha256-7JsOWhMTnxeJfsTVgnnHQt5gYJ8tqELT+s3VDHTPof8=";
    };
    vma = github {
      pin = "VulkanMemoryAllocator.git GIT_TAG v3.4.0";
      owner = "GPUOpen-LibrariesAndSDKs";
      repo = "VulkanMemoryAllocator";
      rev = "v3.4.0";
      hash = "sha256-LBZJcom7G7maF9wpUVeVEJQAJwGy6365INk3VD0/0PM=";
    };
    glm = github {
      pin = "g-truc/glm.git GIT_TAG 1.0.3";
      owner = "g-truc";
      repo = "glm";
      rev = "1.0.3";
      hash = "sha256-6WnVvFiTe1/OYj/oTGpCjZKNFurR9MxJ4zf0nDg0Alk=";
    };
    imgui = github {
      pin = "ocornut/imgui.git GIT_TAG v1.92.9b-docking";
      owner = "ocornut";
      repo = "imgui";
      rev = "v1.92.9b-docking";
      hash = "sha256-PknWLxYuXQ73TCFN+eKOJDNLGbg/ZqKSF6mFxkJG6vI=";
    };
    # NOTE: upstream tracks stb `master`; this is master of 2026-11-07
    stb = github {
      pin = "nothings/stb.git GIT_TAG master";
      owner = "nothings";
      repo = "stb";
      rev = "4e9b368bfc071e97206ea5c6adba68dd0cbf8897";
      hash = "sha256-8kUcP5UWqjX5WncA/fEKO1JzMm7Gp+PsGkb+PGBf6lQ=";
    };
    harfbuzz = github {
      pin = "harfbuzz/harfbuzz.git GIT_TAG 14.6.0";
      owner = "harfbuzz";
      repo = "harfbuzz";
      rev = "14.6.0";
      hash = "sha256-NKM9CNoDUEwCzs7kKOpve1hQmGuzjmUujCMD/h4p5bM=";
    };
    ogg = github {
      pin = "xiph/ogg.git GIT_TAG v1.3.5";
      owner = "xiph";
      repo = "ogg";
      rev = "v1.3.5";
      hash = "sha256-ync2np86Nje1R/g41VLhPhsld+yLZ40Pxv1wNzWCtss=";
    };
    vorbis = github {
      pin = "xiph/vorbis.git GIT_TAG v1.3.7";
      owner = "xiph";
      repo = "vorbis";
      rev = "v1.3.7";
      hash = "sha256-yCnbAxkbZN674F5HVd+DTmotvdtYnkJiO01B6foOiVY=";
    };
    lua51 = tarball {
      pin = "2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333";
      url = "https://www.lua.org/ftp/lua-5.1.5.tar.gz";
      hash = "sha256-QnrgndxTSEgkFPXiWQhkD4aVddWpLaVZIe/ya21WAeQ=";
    };
    google_sbc = tarball {
      pin = "fbb2e0b15d3f6717016bd61db26c134fe9c7231cc748d525714f0a2bca02177d";
      url = "https://github.com/google/libsbc/archive/6e505650145c9973d08a0bdd5e5f5e1914305e40.tar.gz";
      hash = "sha256-cqbCTUgFAIoOnKqVZDdBg5h+wSY98HZyCDWy/uU7RT0=";
    };
    whisper = tarball {
      pin = "57e280cee375ab02425b806ad5146b99f6eb9357e3c2b31357c8a6af2e2e44ae";
      url = "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v1.9.4.tar.gz";
      hash = "sha256-xAFPZnRF0U4o3H46h7q11YEn3mGt3eZk9xDtyOwIz6U=";
    };
    zstd = tarball {
      pin = "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3";
      url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz";
      hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
    };
  };

  # NOTE: the voice part (saying "Jack"); hashes are upstream's, checked again by CMake
  voiceModels = {
    "ggml-base.en-q5_1.bin" = fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en-q5_1.bin";
      sha256 = "4baf70dd0d7c4247ba2b81fafd9c01005ac77c2f9ef064e00dcf195d0e2fdd2f";
    };
    "ggml-small.en-q5_1.bin" = fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en-q5_1.bin";
      sha256 = "bfdff4894dcb76bbf647d56263ea2a96645423f1669176f4844a1bf8e478ad30";
    };
    "ggml-silero-v6.2.0.bin" = fetchurl {
      url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin";
      sha256 = "2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987";
    };
  };

  # NOTE: upstream downloads it from ww2ogg's master; this is the commit that added it
  wwiseCodebooks = fetchurl {
    url = "https://raw.githubusercontent.com/hcs64/ww2ogg/f06705cb6f5af57e85759ceec10f8cf48457b17f/packed_codebooks_aoTuV_603.bin";
    sha256 = "00a93eab267d281401b1efd54e888a2e183299b9e6c446c48d09f701a89d9d27";
  };
}
