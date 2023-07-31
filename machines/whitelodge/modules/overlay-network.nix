{ config, lib, pkgs, ... }:

let
  cfg = config.services.overlay-network;
  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.whitelodge;

  vpnInterface = peerCfg.internal.interface.name;
  otherPeers =
    lib.filterAttrs (peerName: _: peerName != "whitelodge") intranetCfg.peers;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";

  makePeer = peerName:
    { internal, network, ... }: {
      wireguardPeerConfig = {
        PublicKey = internal.publicKey;
        PresharedKeyFile = config.age.secrets."wg-${peerName}2whitelodge".path;
        AllowedIPs = [
          "${internal.interface.ipv4}/32"
          "${internal.interface.ipv6}/128"
          (maskSubnet intranetCfg.subnets.${network}.ipv4)
          (maskSubnet intranetCfg.subnets.${network}.ipv6)
        ];
      };
    };

  makeRoute = network: [
    {
      routeConfig = {
        Destination = maskSubnet intranetCfg.subnets.${network}.ipv4;
        Scope = "link";
        Type = "unicast";
      };
    }
    {
      routeConfig = {
        Destination = maskSubnet intranetCfg.subnets.${network}.ipv6;
        Scope = "link";
        Type = "unicast";
      };
    }
  ];
in {
  options.services.overlay-network = {
    enable = lib.mkEnableOption "overlay-network";
  };

  config = lib.mkIf cfg.enable {
    # Firewall entries.
    networking.localCommands = let
      addToSet = setName: elem:
        "${pkgs.nftables}/bin/nft add element inet firewall ${setName} { ${elem} }";

      makeAccessibleSet = ipProto:
        { internal, network, ... }: [
          internal.interface.${ipProto}
          (maskSubnet intranetCfg.subnets.${network}.${ipProto})
        ];

      accessibleIPv4 = builtins.concatMap (makeAccessibleSet "ipv4")
        (builtins.attrValues otherPeers);

      accessibleIPv6 = builtins.concatMap (makeAccessibleSet "ipv6")
        (builtins.attrValues otherPeers);
    in ''
      ${addToSet "vpn_internal_ipv4"
      (maskSubnet intranetCfg.subnets.vpn-internal.ipv4)}
      ${addToSet "vpn_internal_ipv6"
      (maskSubnet intranetCfg.subnets.vpn-internal.ipv6)}

      ${addToSet "vpn_isolated_ipv4"
      (maskSubnet intranetCfg.subnets.vpn-isolated.ipv4)}
      ${addToSet "vpn_isolated_ipv6"
      (maskSubnet intranetCfg.subnets.vpn-isolated.ipv6)}

      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv4")
      accessibleIPv4}
      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv6")
      accessibleIPv6}
    '';

    # Local DNS records.
    services.unbound.localDomains = intranetCfg.localDomains;

    systemd.network = {
      enable = true;

      # Add each peer's gateway as a Wireguard peer.
      netdevs."90-${vpnInterface}" = {
        netdevConfig = {
          Name = vpnInterface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-pk.path;
          ListenPort = peerCfg.internal.port;
        };

        wireguardPeers = lib.mapAttrsToList makePeer otherPeers;
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

        address = [
          "${peerCfg.internal.interface.ipv4}/${
            builtins.toString vpnSubnet.ipv4.mask
          }"
          "${peerCfg.internal.interface.ipv6}/${
            builtins.toString vpnSubnet.ipv6.mask
          }"
        ];

        # Route traffic to each peer's network to the Wireguard interface.
        # Wireguard takes care of routing to the correct gateway within the
        # tunnel thanks to the AllowedIPs clause of each gateway peer.
        routes = let
          peerValues = builtins.attrValues otherPeers;

          networks = builtins.catAttrs "network" peerValues;
        in builtins.concatMap makeRoute networks;
      };
    };
  };
}