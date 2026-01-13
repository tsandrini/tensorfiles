{
  lib,
  stdenv,
  fetchFromGitLab,
  dtc,
  installShellFiles,
}:

stdenv.mkDerivation {
  pname = "argononed";
  version = "unstable-0.5.x-2025-12-26";

  src = fetchFromGitLab {
    owner = "DarkElvenAngel";
    repo = "argononed";
    rev = "0.5.x";
    hash = "sha256-Uv4cyo3FcHIr4N9s+A0ZMmQU7KYAiClcMOtZPXA6GQQ=";
  };

  # patches = [ ./fix-hardcoded-reboot-poweroff-paths.patch ];

  postPatch = ''
    patchShebangs configure
  '';

  nativeBuildInputs = [ installShellFiles ];

  buildInputs = [ dtc ];

  installPhase = ''
    runHook preInstall

    install -Dm755 build/argononed $out/bin/argononed
    install -Dm755 build/argonone-cli $out/bin/argonone-cli

    # Some branches move files around; adjust paths if needed.
    install -Dm755 build/argonone-shutdown $out/lib/systemd/system-shutdown/argonone-shutdown || true
    install -Dm644 build/argonone.dtbo $out/boot/overlays/argonone.dtbo || true

    install -Dm644 OS/_common/argononed.service $out/lib/systemd/system/argononed.service || true
    install -Dm644 OS/_common/argononed.logrotate $out/etc/logrotate.d/argononed || true
    install -Dm644 LICENSE $out/share/argononed/LICENSE || true

    installShellCompletion --bash --name argonone-cli OS/_common/argonone-cli-complete.bash || true

    runHook postInstall
  '';

  meta = {
    homepage = "https://gitlab.com/DarkElvenAngel/argononed";
    description = "Replacement daemon for the Argon One Raspberry Pi case";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [
      lib.maintainers.misterio77
      lib.maintainers.tsandrini
    ];
  };
}
