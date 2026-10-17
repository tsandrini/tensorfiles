# --- flake-parts/lib/nixos/nginx.nix
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
{ lib }:
with lib;
rec {
  /*
    Merge two `services.nginx.virtualHosts.<name>` attrsets.
    Top-level fields: overlay wins. `locations`: deep merge. `extraConfig`:
    string concat (base first, overlay second).

    *Type*: `mergeVhost :: AttrSet -> AttrSet -> AttrSet`
  */
  mergeVhost =
    # (AttrSet) Base vhost
    base:
    # (AttrSet) Overlay vhost
    overlay:
    (base // overlay)
    // {
      locations = recursiveUpdate (base.locations or { }) (overlay.locations or { });
      extraConfig = (base.extraConfig or "") + (overlay.extraConfig or "");
    };

  /*
    Add `/security.txt` and `/.well-known/security.txt` 308 redirects.
    Consumes `securityTxt` from the input.

    *Type*: `withSecurityTxt :: { securityTxt :: String; ... } -> AttrSet`
  */
  withSecurityTxt =
    { securityTxt, ... }@vhost:
    mergeVhost (removeAttrs vhost [ "securityTxt" ]) {
      locations."= /.well-known/security.txt".return = "308 ${securityTxt}";
      locations."= /security.txt".return = "308 ${securityTxt}";
    };

  /*
    Enable QUIC + HTTP/3 + Alt-Svc. Requires UDP/443 on the firewall and
    `services.nginx.enableQuicBPF = true` on the host for multi-worker
    connection ID routing.

    *Type*: `withHTTP3Quic :: AttrSet -> AttrSet`
  */
  withHTTP3Quic =
    vhost:
    mergeVhost vhost {
      quic = true;
      http3 = true;
      extraConfig = ''
        add_header Alt-Svc 'h3=":443"; ma=86400' always;
      '';
    };

  /*
    Public-facing vhost constructor: ACME + forceSSL + security.txt + HTTP/3.

    *Type*: `mkPublicVhost :: { securityTxt :: String; ... } -> AttrSet`
  */
  mkPublicVhost =
    # (AttrSet) Vhost overrides + `securityTxt`
    vhost:
    # withSecurityTxt (
    withHTTP3Quic (
      mergeVhost {
        enableACME = true;
        forceSSL = true;
      } vhost
    );
  # );

  /*
    Build the HSTS block for `services.nginx.commonHttpConfig`. Default-on for
    all hosts in `virtualHosts`; `useHsts = false` opts out (covers `wwwDomain`
    aliases too). `apexDomain` (if non-null) gets the preload-eligible directive.
    A `$scheme` gate enforces RFC 6797 §7.2 (HSTS only over HTTPS).

    *Type*: `mkHstsCommonHttpConfig :: { virtualHosts :: AttrSet; apexDomain :: Nullable String; maxAge :: Int; } -> String`
  */
  mkHstsCommonHttpConfig =
    {
      # (AttrSet) Vhosts; each entry may set `useHsts = false` and/or `wwwDomain`
      virtualHosts,
      # (Nullable String) Apex hostname that should serve the preload-eligible header
      apexDomain ? null,
      # (Int) Seconds; defaults to 1 year (production target)
      maxAge ? 3600,
    }:
    let
      optOutDomains = concatLists (
        mapAttrsToList (_: v: [ v.domain ] ++ optional (v ? wwwDomain) v.wwwDomain) (
          filterAttrs (_: v: !(v.useHsts or true)) virtualHosts
        )
      );
      apexEntry = optional (
        apexDomain != null
      ) ''"${apexDomain}" "max-age=${toString maxAge}; includeSubDomains; preload";'';
      optOutEntries = map (d: ''"${d}" "";'') optOutDomains;
      mapEntries = concatStringsSep "\n        " (apexEntry ++ optOutEntries);
    in
    ''
      map $host $hsts_value_for_host {
        default "max-age=${toString maxAge}";
        ${mapEntries}
      }
      map $scheme $hsts_header {
        default "";
        https   $hsts_value_for_host;
      }
      add_header Strict-Transport-Security $hsts_header always;
    '';
}
