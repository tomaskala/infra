{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.tailscale;

  user = "tailscaled";
  group = "tailscale";
in
{
  options.infra.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale-api-key.path;
      permitCertUid = config.services.caddy.user;
    };

    security.tpm2.enable = true;

    users = {
      users.${user} = {
        inherit group;
        isSystemUser = true;
        extraGroups = [ config.security.tpm2.tssGroup ];
      };

      groups.${group} = { };
    };

    systemd.services.tailscaled.serviceConfig = {
      User = user;
      Group = group;
      DeviceAllow = [
        "/dev/tun"
        "/dev/net/tun"
        "/dev/tpmrm0 rw"
      ];
      AmbientCapabilities = [
        "CAP_NET_RAW"
        "CAP_NET_ADMIN"
        "CAP_SYS_MODULE"
      ];
      ProtectKernelModules = false;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateMounts = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectSystem = "full";
      ProtectProc = "noaccess";
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@known"
        "~@clock"
        "~@cpu-emulation"
        "~@raw-io"
        "~@reboot"
        "~@mount"
        "~@obsolete"
        "~@swap"
        "~@debug"
        "~@keyring"
        "~@pkey"
      ];
    };
  };
}
