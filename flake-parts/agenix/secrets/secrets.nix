# --- flake-parts/agenix/secrets/secrets.nix
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
let
  flatbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8avUMhkJ8zQ6/uvLGGEhU6VZ00bNDR9nWko7Kk8pbX root@flatbundle";
  jetbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQpLfZTRGfeVkh0tTCZ7Ads5fwYnl3cIj34Fukkymhp root@jetbundle";
  spinorbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1693g0EVyChehwAjJqkKLWD8ZysLbo9TbRZ2B9BcKe root@spinorbundle";
  remotebundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/zORD7glqIeAJNnoW7PFKmZV1eJr46glrSvFDyWH2/ root@nixos";
  pupibundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLvjzkKLhKbaRU/uf3A+pf25rir3y+6mvcbaAxt2DHP root@pupibundle";
  blehbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUem9jyfHkEN3DRNuS896ai1+Pu/vxiQrXoZw0cHxGH root@blehbundle";
  navibundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID4CsU0/G4Qv5YXPfII/7cfXHoUxGmnCDXJKQjkIa0g3 root@navibundle";
  krupikbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2uNUIA6VhPU2kjkK5dNOPzs9ic0oO0Bf5qHGJjzPRq root@krupikbundle";

  hosts = [
    spinorbundle
    jetbundle
    remotebundle
    flatbundle
    pupibundle
    blehbundle
    navibundle
    krupikbundle
  ];

  tsandrini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWrK27cm+rAVKuwDjlJgCuy8Rftg2YOALwtnu7z3Ox1 tsandrini";
  # krupikbundle's own user identity: the box is not mine, the personal key
  # never lives there, so its HM secrets are encrypted to this key instead
  tsandrini-krupikbundle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/x90JoFIcZAJItY3w+8wWi4PID1U2hbIRL12X7U5ev tsandrini@krupikbundle";
  users = [ tsandrini ];
in
{
  # ----------
  # | COMMON |
  # ----------
  "common/nix-conf-global-access-tokens.age".publicKeys = hosts ++ users;
  # claude-code read-only workspace tokens, sourced by workspace .envrc
  "common/claude-code-meteopress-meta-envfile.age".publicKeys = [
    flatbundle
    jetbundle
    navibundle
    krupikbundle
    tsandrini-krupikbundle
  ]
  ++ users;
  "common/claude-code-pesekmudra-meta-envfile.age".publicKeys = [
    flatbundle
    jetbundle
    navibundle
    krupikbundle
    tsandrini-krupikbundle
  ]
  ++ users;
  "common/claude-code-tsandrini-meta-envfile.age".publicKeys = [
    flatbundle
    jetbundle
    navibundle
    krupikbundle
    tsandrini-krupikbundle
  ]
  ++ users;
  # ccdash collector tokens: one per workstation, shared with the hub
  "common/ccdash-collector-token-navibundle.age".publicKeys = [
    navibundle
    pupibundle
  ]
  ++ users;
  "common/ccdash-collector-token-flatbundle.age".publicKeys = [
    flatbundle
    pupibundle
  ]
  ++ users;
  "common/ccdash-collector-token-krupikbundle.age".publicKeys = [
    krupikbundle
    pupibundle
    tsandrini-krupikbundle
  ]
  ++ users;
  # restic repository passwords, shared by the backed-up host and flatbundle
  # (tensorfiles.services.backup.restic.admin)
  "common/backup/restic-remotebundle-password.age".publicKeys = [
    remotebundle
    flatbundle
    navibundle
  ]
  ++ users;
  "common/backup/restic-blehbundle-password.age".publicKeys = [
    blehbundle
    flatbundle
    navibundle
  ]
  ++ users;
  "common/backup/restic-pupibundle-password.age".publicKeys = [
    pupibundle
    flatbundle
    navibundle
  ]
  ++ users;
  # handoff relay encryption, shared by the hosts that push/pull working trees
  # (tensorfiles.hm.programs.handoff)
  "common/handoff-crypt-password.age".publicKeys = [
    flatbundle
    navibundle
    krupikbundle
    tsandrini-krupikbundle
  ]
  ++ users;

  # ---------
  # | HOSTS |
  # ---------
  # --- pupibundle ---
  # --------------------
  "hosts/pupibundle/users/root/system-password.age".publicKeys = [ pupibundle ] ++ [ tsandrini ];
  "hosts/pupibundle/users/tsandrini/system-password.age".publicKeys = [ pupibundle ] ++ [ tsandrini ];
  # ccdash hub: web UI bearer token, Wedos DNS-01 credentials for the *.home cert
  "hosts/pupibundle/ccdash-ui-token.age".publicKeys = [ pupibundle ] ++ [ tsandrini ];
  "hosts/pupibundle/wedos-acme-env.age".publicKeys = [ pupibundle ] ++ [ tsandrini ];
  # Zigbee2MQTT `secret.yaml`: network key, frontend token
  "hosts/pupibundle/zigbee2mqtt-secret.yaml.age".publicKeys = [ pupibundle ] ++ [ tsandrini ];
  # append-only Storage Box key (restic backups)
  "hosts/pupibundle/backup-storagebox-client-ssh-key.age".publicKeys = [
    pupibundle
  ]
  ++ [ tsandrini ];
  # system mail (msmtp) as pupibundle-bot@, the mailbox lives on blehbundle
  "hosts/pupibundle/pupibundle-bot-mail-password.age".publicKeys = [ pupibundle ] ++ [ tsandrini ];

  # --- blehbundle ---
  # --------------------
  "hosts/blehbundle/wg-home-tunnel-privkey.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  # append-only Storage Box key (restic backups)
  "hosts/blehbundle/backup-storagebox-client-ssh-key.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  # services copied over from remotebundle (meta/plans/vps-migration.md)
  "hosts/blehbundle/wedos-acme-env.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/prometheus-ui-basic-auth-file.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  # bearer token of the HA user `prometheus` (scrapes pupibundle's /api/prometheus)
  "hosts/blehbundle/prometheus-ha-token.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/infra-docs-mtpr-basic-auth-file.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/pgadmin-admin-password.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/grafana-bot-mail-password.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/grafana-admin-password.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/grafana-secret-key.age".publicKeys = [ blehbundle ] ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/rspamd-ui-basic-auth-file.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/security-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/t-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/business-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/monitoring-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/shopping-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/newsletters-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/grafana-bot-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/pupibundle-bot-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/immich-bot-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/git-bot-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];
  "hosts/blehbundle/mailserver/testing-at-tsandrini-dot-sh.age".publicKeys = [
    blehbundle
  ]
  ++ [ tsandrini ];

  # --- navibundle ---
  # --------------------
  "hosts/navibundle/users/root/system-password.age".publicKeys = [ navibundle ] ++ [ tsandrini ];
  "hosts/navibundle/users/tsandrini/system-password.age".publicKeys = [ navibundle ] ++ [ tsandrini ];
  # full-access Storage Box key (restic admin commands)
  "hosts/navibundle/backup-storagebox-admin-ssh-key.age".publicKeys = [ navibundle ] ++ [ tsandrini ];

  # --- krupikbundle ---
  # --------------------
  # NOTE: deliberately nothing else: no restic passwords, no Storage Box keys
  "hosts/krupikbundle/users/root/system-password.age".publicKeys = [ krupikbundle ] ++ [ tsandrini ];
  "hosts/krupikbundle/users/tsandrini/system-password.age".publicKeys = [
    krupikbundle
  ]
  ++ [ tsandrini ];
  "hosts/krupikbundle/wg-home-tunnel-privkey.age".publicKeys = [ krupikbundle ] ++ [ tsandrini ];

  # --- flatbundle ---
  # --------------------
  "hosts/flatbundle/users/root/system-password.age".publicKeys = [ flatbundle ] ++ [ tsandrini ];
  "hosts/flatbundle/users/tsandrini/system-password.age".publicKeys = [ flatbundle ] ++ [ tsandrini ];
  # nix-daemon's key for the remote builders (`nix-ssh` user there)
  "hosts/flatbundle/nix-remote-builder-ssh-key.age".publicKeys = [ flatbundle ] ++ [ tsandrini ];
  # full-access Storage Box key (restic admin commands)
  "hosts/flatbundle/backup-storagebox-admin-ssh-key.age".publicKeys = [ flatbundle ] ++ [ tsandrini ];

  # --- jetbundle ---
  # --------------------
  "hosts/jetbundle/users/root/system-password.age".publicKeys = [ jetbundle ] ++ [ tsandrini ];
  "hosts/jetbundle/users/tsandrini/system-password.age".publicKeys = [ jetbundle ] ++ [ tsandrini ];

  # --- remotebundle ---
  # --------------------
  "hosts/remotebundle/users/root/system-password.age".publicKeys = [ remotebundle ] ++ [ tsandrini ];
  "hosts/remotebundle/users/tsandrini/system-password.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/wedos-wapi-credentials.age".publicKeys = [
    remotebundle
  ];
  # append-only Storage Box key (restic backups)
  "hosts/remotebundle/backup-storagebox-client-ssh-key.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  # mailserver
  "hosts/remotebundle/mailserver/t-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/business-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/security-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/monitoring-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/shopping-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/newsletters-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/grafana-bot-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/git-bot-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ];
  "hosts/remotebundle/mailserver/immich-bot-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/mailserver/testing-at-tsandrini-dot-sh.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  # rspamd
  "hosts/remotebundle/mailserver/rspamd-ui-basic-auth-file.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  # grafana
  "hosts/remotebundle/grafana-admin-password.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/grafana-secret-key.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/grafana-bot-mail-password.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  # pgadmin
  "hosts/remotebundle/pgadmin-admin-password.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  # firefly
  "hosts/remotebundle/firefly-iii-app-key.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/wg-home-tunnel-privkey.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/prometheus-ui-basic-auth-file.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];
  "hosts/remotebundle/infra-docs-mtpr-basic-auth-file.age".publicKeys = [
    remotebundle
  ]
  ++ [ tsandrini ];

  # --- spinorbundle ---
  # --------------------
  "hosts/spinorbundle/users/root/system-password.age".publicKeys = [ spinorbundle ] ++ [ tsandrini ];
  "hosts/spinorbundle/users/tsandrini/system-password.age".publicKeys = [
    spinorbundle
  ]
  ++ [ tsandrini ];
}
