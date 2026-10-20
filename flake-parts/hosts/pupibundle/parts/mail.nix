# --- flake-parts/hosts/pupibundle/parts/mail.nix
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
#
# System mail: msmtp is the Pi's sendmail and submits as `pupibundle-bot@`
# to the mailserver on blehbundle; restic mails its failed runs to the
# monitoring mailbox. Root-only (the password is a root-owned secret, the
# wrapper is not setuid), which is all the failure units need. Waits for
# its secret.
{
  secretsPath,
  infraVars,
}:
{
  config,
  lib,
  hostName,
  ...
}:
let
  mailVars = infraVars.hosts."blehbundle".services.mailserver;
  account = "${hostName}-bot@${mailVars.primaryDomain}";

  passwordSecret = "hosts/${hostName}/${hostName}-bot-mail-password";
  mailCheck = builtins.pathExists "${secretsPath}/${passwordSecret}.age";
in
{
  config = lib.mkMerge [
    # |----------------------------------------------------------------------| #
    {
      warnings = lib.optional (!mailCheck) "mail: ${passwordSecret}.age is missing, no system mail.";
    }
    # |----------------------------------------------------------------------| #
    (lib.mkIf mailCheck {
      programs.msmtp = {
        enable = true;
        defaults.syslog = "LOG_MAIL";
        accounts.default = {
          host = mailVars.fqdn;
          port = 465;
          tls = true;
          tls_starttls = false;
          auth = true;
          user = account;
          from = account;
          passwordeval = "cat ${config.age.secrets.${passwordSecret}.path}";
        };
      };

      age.secrets.${passwordSecret}.file = "${secretsPath}/${passwordSecret}.age";

      tensorfiles.services.backup.restic.notifyEmail = infraVars.common.contacts.monitoringEmail;
    })
    # |----------------------------------------------------------------------| #
  ];
}
