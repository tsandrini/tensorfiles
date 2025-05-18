{ localFlake, secretsPath }:
{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkMerge
    types
    mkEnableOption
    mkOption
    attrNames
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmProfileLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkAgenixEnableOption mkSubmodulesOption;
  inherit (localFlake.lib.attrsets) mapToAttrsAndMerge;
  inherit (localFlake.lib.strings) sanitizeEmailForNixStorePath;

  cfg = config.tensorfiles.hm.profiles.accounts.tsandrini;
  _ = mkOverrideAtHmProfileLevel;

  agenixCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.security.agenix") && cfg.agenix.enable;

  defaultDomain = "tsandrini.sh";
in
{
  options.tensorfiles.hm.profiles.accounts.tsandrini = {
    enable = mkEnableOption ''
      TODO
    '';

    agenix = {
      enable = mkAgenixEnableOption;
    };

    email = {
      enable =
        mkEnableOption ''
          Enable email accounts configuration.
        ''
        // {
          default = true;
        };

      accounts =
        mkSubmodulesOption (_account: {

          enable =
            mkEnableOption ''
              Enable the account.
            ''
            // {
              default = true;
            };

          agenixPassword = {
            enable = mkEnableOption ''
              TODO
            '';

            passwordSecretsPath = mkOption {
              type = types.str;
              default = "common/accounts/${sanitizeEmailForNixStorePath _account}";
              description = ''
                TODO
              '';
            };
          };
        })
        // {
          default = {
            "tomas.sandrini@seznam.cz" = { };
            "WareCzech@gmail.com" = { };
            "t@${defaultDomain}" = { };
            "business@${defaultDomain}" = { };
            "security@${defaultDomain}" = { };
            "shopping@${defaultDomain}" = { };
            "newsletters@${defaultDomain}" = { };
            "monitoring@${defaultDomain}" = { };
          };
        };
    };
  };

  # NOTE thunderbird doesn't support the `passwordCommand` so for me personally
  # its kinda useless, but I prepared it nonetheless
  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."tomas.sandrini@seznam.cz".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."tomas.sandrini@seznam.cz";
        in
        {
          "tomas.sandrini@seznam.cz" = {
            address = _ "tomas.sandrini@seznam.cz";
            userName = _ "tomas.sandrini@seznam.cz"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "imap.seznam.cz";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "smtp.seznam.cz";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."WareCzech@gmail.com".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."WareCzech@gmail.com";
        in
        {
          "WareCzech@gmail.com" = {
            address = _ "WareCzech@gmail.com";
            userName = _ "WareCzech"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "imap.gmail.com";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "smtp.gmail.com";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."t@${defaultDomain}".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."t@${defaultDomain}";
        in
        {
          "t@${defaultDomain}" = {
            address = _ "t@${defaultDomain}";
            userName = _ "t@${defaultDomain}"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.${defaultDomain}";
            imap.port = _ 993;
            primary = _ true;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "mail.${defaultDomain}";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."business@${defaultDomain}".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."business@${defaultDomain}";
        in
        {
          "business@${defaultDomain}" = {
            address = _ "business@${defaultDomain}";
            userName = _ "business@${defaultDomain}"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.${defaultDomain}";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "mail.${defaultDomain}";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."security@${defaultDomain}".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."security@${defaultDomain}";
        in
        {
          "security@${defaultDomain}" = {
            address = _ "security@${defaultDomain}";
            userName = _ "security@${defaultDomain}"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.${defaultDomain}";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "mail.${defaultDomain}";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."shopping@tsandrini.sh".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."shopping@tsandrini.sh";
        in
        {
          "shopping@tsandrini.sh" = {
            address = _ "shopping@tsandrini.sh";
            userName = _ "shopping@tsandrini.sh"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.tsandrini.sh";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "mail.tsandrini.sh";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."newsletters@${defaultDomain}".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."newsletters@${defaultDomain}";
        in
        {
          "newsletters@${defaultDomain}" = {
            address = _ "newsletters@${defaultDomain}";
            userName = _ "newsletters@${defaultDomain}"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.${defaultDomain}";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "mail.${defaultDomain}";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."monitoring@${defaultDomain}".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."monitoring@${defaultDomain}";
        in
        {
          "monitoring@${defaultDomain}" = {
            address = _ "monitoring@${defaultDomain}";
            userName = _ "monitoring@${defaultDomain}"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.${defaultDomain}";
            imap.port = _ 993;
            primary = _ false;
            realName = _ "Tomáš Sandrini";
            smtp.host = _ "mail.${defaultDomain}";
            smtp.port = _ 587;
            smtp.tls.useStartTls = _ true;
            thunderbird.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.thunderbird");
            neomutt.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.neomutt");
            notmuch.enable = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.notmuch");

            passwordCommand =
              mkIf (agenixCheck && accountCfg.agenixPassword.enable)
                "cat ${config.age.secrets.${accountCfg.agenixPassword.passwordSecretsPath}.path}";
          };
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && agenixCheck) {
      age.secrets = mapToAttrsAndMerge (attrNames cfg.email.accounts) (
        _account:
        let
          accountCfg = cfg.email.accounts.${_account};
        in
        with accountCfg.agenixPassword;
        {
          "${passwordSecretsPath}" = mkIf enable {
            file = _ (secretsPath + "/${passwordSecretsPath}.age");
            # mode = _ "600";
            # owner = _ config.home.username; # NOTE not available in HM module
          };
        }
      );
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
