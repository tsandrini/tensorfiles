# --- flake-parts/modules/nixos/networking/ssh-aliases.nix
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
{
  localFlake,
  infraVars,
  pubkeys,
}:
{
  config,
  lib,
  hostName,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    concatStrings
    filterAttrs
    literalExpression
    mapAttrs
    mapAttrsToList
    optionalString
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.networking.ssh-aliases;
  _ = mkOverrideAtModuleLevel;

  # Every infraVars host except this one that has something to connect to.
  # An optional `ssh` attrset on the host overrides the derived values.
  derivedHosts = mapAttrs (
    name: host:
    let
      ssh = host.ssh or { };
    in
    {
      hostName = ssh.hostName or host.wgAddress or host.address or null;
      port = ssh.port or infraVars.common.services.openssh.defaultPort;
      user = ssh.user or cfg.defaultUser;
      hostKey = pubkeys.hosts.${name}.hostKey or null;
    }
  ) (filterAttrs (name: _host: name != hostName) infraVars.hosts);

  usableHosts = filterAttrs (
    _name: host: host.hostName != null && host.hostName != "localhost"
  ) cfg.hosts;

  hostSubmodule = {
    options = {
      hostName = mkOption {
        type = types.nullOr types.str;
        description = "Address to connect to. `null` drops the alias.";
      };
      port = mkOption {
        type = types.port;
        description = "SSH port.";
      };
      user = mkOption {
        type = types.str;
        description = "User to log in as.";
      };
      hostKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Public host key to pin in `known_hosts`, `null` leaves it unpinned.";
      };
    };
  };
in
{
  options.tensorfiles.networking.ssh-aliases = {
    enable = mkEnableOption ''
      Enables NixOS module that turns the hosts in `infraVars` into system-wide
      ssh aliases, so `ssh blehbundle` works without remembering addresses or
      ports.

      The alias is the host name. The address is the host's `wgAddress`, else
      its `address`; the port is the fleet-wide sshd port; the user is
      `defaultUser`. A host may override any of these with an `ssh` attrset
      (`hostName`, `port`, `user`) in `infraVars`. Hosts with a `hostKey` in
      the agenix `pubkeys` get it pinned in `known_hosts`.
    '';

    defaultUser = mkOption {
      type = types.str;
      default = "tsandrini";
      description = "User for hosts that do not set `ssh.user`.";
    };

    hosts = mkOption {
      type = types.attrsOf (types.submodule hostSubmodule);
      default = derivedHosts;
      defaultText = literalExpression "<derived from infraVars.hosts and pubkeys.hosts>";
      description = ''
        Aliases to generate, keyed by alias. Defaults to every other host in
        `infraVars`; set an alias to `{ hostName = null; }` to drop it or add
        your own.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      extraConfig = concatStrings (
        mapAttrsToList (name: host: ''
          Host ${name}
            HostName ${host.hostName}
            Port ${toString host.port}
            User ${host.user}
          ${optionalString (host.hostKey != null) "  HostKeyAlias ${name}\n"}
        '') usableHosts
      );

      knownHosts = mapAttrs (_name: host: { publicKey = _ host.hostKey; }) (
        filterAttrs (_name: host: host.hostKey != null) usableHosts
      );
    };
  };

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
