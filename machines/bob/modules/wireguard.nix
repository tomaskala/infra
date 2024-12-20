{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs) infra;

  cfg = config.infra.wireguard;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.bob;
in
{
  options.infra.wireguard = {
    enable = lib.mkEnableOption "wireguard";
  };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;

      netdevs."90-${deviceCfg.wireguard.isolated.name}" = {
        netdevConfig = {
          Name = deviceCfg.wireguard.isolated.name;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile =
            assert deviceCfg.wireguard.isolated.privateKeyFile != null;
            deviceCfg.wireguard.isolated.privateKeyFile;
        };

        wireguardPeers = [
          {
            PublicKey = intranetCfg.devices.whitelodge.wireguard.isolated.publicKey;
            PresharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
            AllowedIPs = [
              (infra.ipAddressMasked intranetCfg.devices.whitelodge.wireguard.isolated.ipv4 32)
              (infra.ipAddressMasked intranetCfg.devices.whitelodge.wireguard.isolated.ipv6 128)
            ];
            Endpoint = "${intranetCfg.devices.whitelodge.external.wan.ipv4}:${builtins.toString intranetCfg.devices.whitelodge.wireguard.isolated.port}";
            PersistentKeepalive = 25;
          }
        ];
      };

      networks."90-${deviceCfg.wireguard.isolated.name}" = {
        matchConfig.Name = deviceCfg.wireguard.isolated.name;

        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;
        };

        address = [
          (infra.ipAddressMasked deviceCfg.wireguard.isolated.ipv4 intranetCfg.wireguard.isolated.ipv4.mask)
          (infra.ipAddressMasked deviceCfg.wireguard.isolated.ipv6 intranetCfg.wireguard.isolated.ipv6.mask)
        ];
      };
    };
  };
}
