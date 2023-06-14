{ config, lib, ... }:

{
  config.age.secrets = let
    makeSecret = name: {
      inherit name;
      value.file = "/root/secrets/${name}.age";
    };

    makeSystemdNetworkReadableSecret = name:
      lib.recursiveUpdate (makeSecret name) {
        value = {
          mode = "0640";
          owner = "root";
          group = "systemd-network";
        };
      };

    secrets = builtins.map makeSecret [
      "users-tomas-password-${config.networking.hostName}"
      "miniflux-admin-credentials"
    ];

    systemdNetworkReadableSecrets =
      builtins.map makeSystemdNetworkReadableSecret [
        "wg-${config.networking.hostName}-pk"
        "wg-bob2${config.networking.hostName}-psk"
        "wg-tomas-phone2${config.networking.hostName}-psk"
        "wg-martin-windows2${config.networking.hostName}-psk"
        "wg-blacklodge2${config.networking.hostName}-psk"
      ];
  in builtins.listToAttrs (secrets ++ systemdNetworkReadableSecrets);
}
