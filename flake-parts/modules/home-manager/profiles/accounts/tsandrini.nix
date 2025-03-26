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
            "t@tsandrini.sh" = { };
            "WareCzech@gmail.com" = { };
            "t@tsandrini.sh" = { };
            "business@tsandrini.sh" = { };
            "security@tsandrini.sh" = { };
            "shopping@tsandrini.sh" = { };
            "newsletters@tsandrini.sh" = { };
          };
        };
    };
  };

  # NOTE thunderbird doesn't support the `passwordCommand` so for me personally
  # its kinda useless, but I prepared it nonetheless
  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.email.enable && cfg.email.accounts."t@tsandrini.sh".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."t@tsandrini.sh";
        in
        {
          "t@tsandrini.sh" = {
            address = _ "t@tsandrini.sh";
            userName = _ "t@tsandrini.sh"; # TODO https://github.com/nix-community/home-manager/issues/3712
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
    (mkIf (cfg.email.enable && cfg.email.accounts."t@tsandrini.sh".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."t@tsandrini.sh";
        in
        {
          "t@tsandrini.sh" = {
            address = _ "t@tsandrini.sh";
            userName = _ "t@tsandrini.sh"; # TODO https://github.com/nix-community/home-manager/issues/3712
            imap.host = _ "mail.tsandrini.sh";
            imap.port = _ 993;
            primary = _ true;
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
    (mkIf (cfg.email.enable && cfg.email.accounts."business@tsandrini.sh".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."business@tsandrini.sh";
        in
        {
          "business@tsandrini.sh" = {
            address = _ "business@tsandrini.sh";
            userName = _ "business@tsandrini.sh"; # TODO https://github.com/nix-community/home-manager/issues/3712
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
    (mkIf (cfg.email.enable && cfg.email.accounts."security@tsandrini.sh".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."security@tsandrini.sh";
        in
        {
          "security@tsandrini.sh" = {
            address = _ "security@tsandrini.sh";
            userName = _ "security@tsandrini.sh"; # TODO https://github.com/nix-community/home-manager/issues/3712
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
    (mkIf (cfg.email.enable && cfg.email.accounts."newsletters@tsandrini.sh".enable) {
      accounts.email.accounts =
        let
          accountCfg = cfg.email.accounts."newsletters@tsandrini.sh";
        in
        {
          "newsletters@tsandrini.sh" = {
            address = _ "newsletters@tsandrini.sh";
            userName = _ "newsletters@tsandrini.sh"; # TODO https://github.com/nix-community/home-manager/issues/3712
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
