{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  name = "tensorfiles-intranet-unauthorized";

  src = ./.;

  nativeBuildInputs = [ ];

  installPhase = ''
    mkdir -p $out

    cp -avr $src/assets $out/assets
    cp -av $src/index.html $out/
  '';

  meta = {
    description = "Nginx root package for an unauthorized page for the wg intranet access.";
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.tsandrini ];
  };
}
