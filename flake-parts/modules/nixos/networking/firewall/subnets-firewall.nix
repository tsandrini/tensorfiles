# --- flake-parts/nixos/modules/networking/firewall/subnets-firewall.nix
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
{ localFlake }:
{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    concatMapStringsSep
    optionalString
    unique
    flatten
    attrNames
    attrValues
    filterAttrs
    hasInfix
    lists
    ;

  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.networking.firewall.subnets-firewall;
  _ = mkOverrideAtModuleLevel;

  policyType = types.submodule (_: {
    options = {
      allowedTCPPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
      };
      allowedUDPPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
      };

      allowedTCPPortRanges = mkOption {
        type = types.listOf (
          types.submodule (_: {
            options = {
              from = mkOption { type = types.port; };
              to = mkOption { type = types.port; };
            };
          })
        );
        default = [ ];
      };

      allowedUDPPortRanges = mkOption {
        type = types.listOf (
          types.submodule (_: {
            options = {
              from = mkOption { type = types.port; };
              to = mkOption { type = types.port; };
            };
          })
        );
        default = [ ];
      };
    };
  });

  isV6 = cidr: hasInfix ":" cidr;

  defaultSubnetsRendered = builtins.listToAttrs (
    map (cidr: {
      name = cidr;
      value = cfg.defaultSubnets;
    }) cfg.defaultSubnetsList
  );

  effectiveSubnets = defaultSubnetsRendered // cfg.subnets;

  subnetsV4 = filterAttrs (cidr: _: !isV6 cidr) effectiveSubnets;
  subnetsV6 = filterAttrs (cidr: _: isV6 cidr) effectiveSubnets;

  # ----- helpers to collect unions across *all* subnets (v4+v6) -----
  allPolicies = attrValues effectiveSubnets;

  unionPorts = protoKey: unique (flatten (map (p: p.${protoKey}) allPolicies));
  unionRanges = rangeKey: unique (flatten (map (p: p.${rangeKey}) allPolicies));

  allTcpPorts = unionPorts "allowedTCPPorts";
  allUdpPorts = unionPorts "allowedUDPPorts";
  allTcpRanges = unionRanges "allowedTCPPortRanges";
  allUdpRanges = unionRanges "allowedUDPPortRanges";

  # ----- iptables rendering -----
  iptActionTcp4 = if cfg.defaultAction == "reject" then "REJECT --reject-with tcp-reset" else "DROP";
  iptActionUdp4 =
    if cfg.defaultAction == "reject" then "REJECT --reject-with icmp-port-unreachable" else "DROP";
  iptActionTcp6 = if cfg.defaultAction == "reject" then "REJECT --reject-with tcp-reset" else "DROP";
  iptActionUdp6 =
    if cfg.defaultAction == "reject" then "REJECT --reject-with icmp6-port-unreachable" else "DROP";

  chunkPorts = ports: lists.chunked 15 (map toString ports);
  joinPorts = ps: concatMapStringsSep "," (x: x) ps;

  # build accept rules for one subnet & proto, chunking ports to avoid multiport limit
  iptAcceptSubnet =
    iptCmd: chain: proto: cidr: ports: ranges:
    let
      portChunks = chunkPorts ports;
      portsRules = concatMapStringsSep "\n" (
        ps:
        "${iptCmd} -w -A ${chain} -p ${proto} -s ${cidr} -m multiport --dports ${joinPorts ps} -j ACCEPT"
      ) portChunks;

      rangeRules = concatMapStringsSep "\n" (
        r:
        "${iptCmd} -w -A ${chain} -p ${proto} -s ${cidr} --dport ${toString r.from}:${toString r.to} -j ACCEPT"
      ) ranges;
    in
    ''
      ${optionalString (ports != [ ]) portsRules}
      ${optionalString (ranges != [ ]) rangeRules}
    '';

  # jump rules (NEW only) from INPUT -> our chain for union ports/ranges
  iptJumpUnion =
    iptCmd: chain: proto: ports: ranges:
    let
      portChunks = chunkPorts ports;

      jumpPorts = concatMapStringsSep "\n" (ps: ''
        ${iptCmd} -w -C INPUT -p ${proto} -m conntrack --ctstate NEW -m multiport --dports ${joinPorts ps} -j ${chain} 2>/dev/null \
          || ${iptCmd} -w -I INPUT -p ${proto} -m conntrack --ctstate NEW -m multiport --dports ${joinPorts ps} -j ${chain}
      '') portChunks;

      jumpRanges = concatMapStringsSep "\n" (r: ''
        ${iptCmd} -w -C INPUT -p ${proto} -m conntrack --ctstate NEW --dport ${toString r.from}:${toString r.to} -j ${chain} 2>/dev/null \
          || ${iptCmd} -w -I INPUT -p ${proto} -m conntrack --ctstate NEW --dport ${toString r.from}:${toString r.to} -j ${chain}
      '') ranges;
    in
    ''
      ${optionalString (ports != [ ]) jumpPorts}
      ${optionalString (ranges != [ ]) jumpRanges}
    '';

  iptStopJumps =
    iptCmd: chain: proto: ports: ranges:
    let
      portChunks = chunkPorts ports;

      delPorts = concatMapStringsSep "\n" (
        ps:
        "${iptCmd} -w -D INPUT -p ${proto} -m conntrack --ctstate NEW -m multiport --dports ${joinPorts ps} -j ${chain} 2>/dev/null || true"
      ) portChunks;

      delRanges = concatMapStringsSep "\n" (
        r:
        "${iptCmd} -w -D INPUT -p ${proto} -m conntrack --ctstate NEW --dport ${toString r.from}:${toString r.to} -j ${chain} 2>/dev/null || true"
      ) ranges;
    in
    ''
      ${optionalString (ports != [ ]) delPorts}
      ${optionalString (ranges != [ ]) delRanges}
    '';

  iptablesBlock = ''
    # --- subnet-firewall (iptables fallback) ---
    iptables -w -N TF_SUBNETFW4_TCP 2>/dev/null || true
    iptables -w -F TF_SUBNETFW4_TCP
    iptables -w -N TF_SUBNETFW4_UDP 2>/dev/null || true
    iptables -w -F TF_SUBNETFW4_UDP

    ip6tables -w -N TF_SUBNETFW6_TCP 2>/dev/null || true
    ip6tables -w -F TF_SUBNETFW6_TCP
    ip6tables -w -N TF_SUBNETFW6_UDP 2>/dev/null || true
    ip6tables -w -F TF_SUBNETFW6_UDP

    # jumps for the union of all declared ports/ranges (NEW only)
    ${iptJumpUnion "iptables" "TF_SUBNETFW4_TCP" "tcp" allTcpPorts allTcpRanges}
    ${iptJumpUnion "iptables" "TF_SUBNETFW4_UDP" "udp" allUdpPorts allUdpRanges}
    ${iptJumpUnion "ip6tables" "TF_SUBNETFW6_TCP" "tcp" allTcpPorts allTcpRanges}
    ${iptJumpUnion "ip6tables" "TF_SUBNETFW6_UDP" "udp" allUdpPorts allUdpRanges}

    # allow rules per subnet (IPv4)
    ${concatMapStringsSep "\n" (
      cidr:
      let
        pol = subnetsV4.${cidr};
      in
      ''
        ${iptAcceptSubnet "iptables" "TF_SUBNETFW4_TCP" "tcp" cidr (pol.allowedTCPPorts or [ ]) (
          pol.allowedTCPPortRanges or [ ]
        )}
        ${iptAcceptSubnet "iptables" "TF_SUBNETFW4_UDP" "udp" cidr (pol.allowedUDPPorts or [ ]) (
          pol.allowedUDPPortRanges or [ ]
        )}
      ''
    ) (attrNames subnetsV4)}

    # allow rules per subnet (IPv6)
    ${concatMapStringsSep "\n" (
      cidr:
      let
        pol = subnetsV6.${cidr};
      in
      ''
        ${iptAcceptSubnet "ip6tables" "TF_SUBNETFW6_TCP" "tcp" cidr (pol.allowedTCPPorts or [ ]) (
          pol.allowedTCPPortRanges or [ ]
        )}
        ${iptAcceptSubnet "ip6tables" "TF_SUBNETFW6_UDP" "udp" cidr (pol.allowedUDPPorts or [ ]) (
          pol.allowedUDPPortRanges or [ ]
        )}
      ''
    ) (attrNames subnetsV6)}

    # default action if it matched our union ports/ranges but didn't match an allow rule
    ${optionalString ((allTcpPorts != [ ]) || (allTcpRanges != [ ])) ''
      iptables  -w -A TF_SUBNETFW4_TCP -j ${iptActionTcp4}
      ip6tables -w -A TF_SUBNETFW6_TCP -j ${iptActionTcp6}
    ''}
    ${optionalString ((allUdpPorts != [ ]) || (allUdpRanges != [ ])) ''
      iptables  -w -A TF_SUBNETFW4_UDP -j ${iptActionUdp4}
      ip6tables -w -A TF_SUBNETFW6_UDP -j ${iptActionUdp6}
    ''}
  '';

  iptablesStopBlock = ''
    # --- subnet-firewall cleanup (iptables fallback) ---
    ${iptStopJumps "iptables" "TF_SUBNETFW4_TCP" "tcp" allTcpPorts allTcpRanges}
    ${iptStopJumps "iptables" "TF_SUBNETFW4_UDP" "udp" allUdpPorts allUdpRanges}
    ${iptStopJumps "ip6tables" "TF_SUBNETFW6_TCP" "tcp" allTcpPorts allTcpRanges}
    ${iptStopJumps "ip6tables" "TF_SUBNETFW6_UDP" "udp" allUdpPorts allUdpRanges}

    iptables  -w -F TF_SUBNETFW4_TCP 2>/dev/null || true
    iptables  -w -X TF_SUBNETFW4_TCP 2>/dev/null || true
    iptables  -w -F TF_SUBNETFW4_UDP 2>/dev/null || true
    iptables  -w -X TF_SUBNETFW4_UDP 2>/dev/null || true

    ip6tables -w -F TF_SUBNETFW6_TCP 2>/dev/null || true
    ip6tables -w -X TF_SUBNETFW6_TCP 2>/dev/null || true
    ip6tables -w -F TF_SUBNETFW6_UDP 2>/dev/null || true
    ip6tables -w -X TF_SUBNETFW6_UDP 2>/dev/null || true
  '';
in
{
  options.tensorfiles.networking.firewall.subnets-firewall = {
    enable = mkEnableOption ''
      Subnet-scoped firewall rules (like networking.firewall.allowed*Ports,
      but restricted to specific CIDR source ranges).
    '';

    defaultAction = mkOption {
      type = types.enum [
        "drop"
        "reject"
      ];
      default = "drop";
      description = "What to do with non-allowlisted traffic for the declared ports/ranges.";
    };

    # passthrough to NixOS networking.firewall allowed* ports/ranges
    nixosPassthrough = mkOption {
      type = policyType;
      default = { };
      description = ''
        Pass-through for NixOS `networking.firewall.allowed*` options (global, non-subnet-scoped).
        Useful to keep all firewall declarations under this module.
      '';
      example = {
        allowedTCPPorts = [
          22
          443
        ];
        allowedUDPPorts = [ 53 ];
        allowedTCPPortRanges = [
          {
            from = 8000;
            to = 8080;
          }
        ];
      };
    };

    defaultSubnetsList = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of CIDRs that should automatically receive the policy defined in
        `defaultSubnets`. These are materialized into `subnets` at eval time,
        and any explicitly defined `subnets.<cidr>` entry overrides the default.
      '';
      example = [
        "10.5.0.0/24"
        "10.0.33.13/32"
        "10.0.0.0/24"
      ];
    };

    defaultSubnets = mkOption {
      type = policyType;
      default = { };
      description = ''
        The policy applied to every CIDR in `defaultSubnetsList`.
        (Same schema as a single `subnets.<cidr>` entry.)
      '';
      example = {
        allowedTCPPorts = [
          22
          2222
        ];
        allowedUDPPorts = [
          80
          443
        ];
        allowedTCPPortRanges = [
          {
            from = 8000;
            to = 8080;
          }
        ];
      };
    };

    subnets = mkOption {
      type = types.attrsOf policyType;
      default = { };
      description = ''
        Attrset keyed by CIDR (IPv4 or IPv6). Each entry defines ports (and port ranges)
        that are reachable *only* from that CIDR.

        Note: defaults from `defaultSubnetsList/defaultSubnets` are merged in automatically,
        and explicit entries here override those defaults on key collision.
      '';
      example = {
        "10.10.0.0/24" = {
          allowedTCPPorts = [
            80
            443
            2222
          ];
        };
        "fd00::/8" = {
          allowedTCPPorts = [ 2222 ];
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      networking.firewall.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
    {
      networking.firewall = {
        inherit (cfg.nixosPassthrough)
          allowedTCPPorts
          allowedUDPPorts
          allowedTCPPortRanges
          allowedUDPPortRanges
          ;
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf (!config.networking.nftables.enable) {
      networking.firewall.extraCommands = lib.mkAfter iptablesBlock;
      networking.firewall.extraStopCommands = lib.mkAfter iptablesStopBlock;
    })
    # |----------------------------------------------------------------------| #
    (mkIf config.networking.nftables.enable {
      networking.nftables.ruleset = lib.mkAfter ''
        # subnet-firewall: inject into NixOS firewall
        ${lib.concatMapStringsSep "\n" (
          cidr:
          let
            pol = effectiveSubnets.${cidr};
            tcpPorts = pol.allowedTCPPorts or [ ];
            udpPorts = pol.allowedUDPPorts or [ ];
            tcpRanges = pol.allowedTCPPortRanges or [ ];
            udpRanges = pol.allowedUDPPortRanges or [ ];

            mkPortSet =
              ports: ranges:
              let
                items = (map toString ports) ++ (map (r: "${toString r.from}-${toString r.to}") ranges);
              in
              "{ ${lib.concatMapStringsSep ", " (x: x) items} }";

            fam = if lib.hasInfix ":" cidr then "ip6" else "ip";
            saddr = if fam == "ip6" then "ip6 saddr" else "ip saddr";

            tcpOk = (tcpPorts != [ ]) || (tcpRanges != [ ]);
            udpOk = (udpPorts != [ ]) || (udpRanges != [ ]);
          in
          ''
            ${lib.optionalString tcpOk ''
              insert rule inet nixos-fw input-allow ${saddr} ${cidr} tcp dport ${mkPortSet tcpPorts tcpRanges} accept
            ''}
            ${lib.optionalString udpOk ''
              insert rule inet nixos-fw input-allow ${saddr} ${cidr} udp dport ${mkPortSet udpPorts udpRanges} accept
            ''}
          ''
        ) (lib.attrNames effectiveSubnets)}
      '';
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
