{ config, lib, ... }:

let
  cfg = config.infra.audiobookshelf;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.audiobookshelf = {
    enable = lib.mkEnableOption "audiobookshelf";

    hostDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this host";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain of this service";
    };

    booksDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory where the books are stored";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      audiobookshelf = {
        enable = true;
        openFirewall = false;
        host = "unix//run/audiobookshelf/audiobookshelf.sock";
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy unix//run/audiobookshelf/audiobookshelf.sock
          '';
        };
      };
    };

    infra.authelia.clients.audiobookshelf = {
      clientID = "loHBtDZmyZrON3H0DtuLwaoNOC0aEGydqQW2WLdam~z2aR8doXs40ew5LIsg8l0cAlIaA554";
      clientSecret = "$pbkdf2-sha512$310000$g7HQizpcxTUErJjpTczmXA$lM1wLml0fxE2.0mwmrnVNu/jHah/uKkjW4fJ2dxWnZW0a.VCnaqPhBJiZn2WVsJVsOV/8QrWkB7wwdQyOQ8mJA";
      redirectURIs = [
        "https://${domain}/auth/openid/callback"
        "https://${domain}/auth/openid/mobile-redirect"
        "audiobookshelf://oauth"
      ];
    };

    systemd.services.audiobookshelf.serviceConfig = {
      RuntimeDirectory = "audiobookshelf";
      # Disallow group access to the state directory. Caddy must be in the same group as audiobookshelf
      # in order to access the Unix socket, but it shouldn't be able to access anything else.
      StateDirectoryMode = "0700";

      NoNewPrivileges = true;
      LockPersonality = true;
      PrivateTmp = true;
      PrivateDevices = true;
      RemoveIPC = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;

      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;

      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ReadOnlyPaths = [ cfg.booksDir ];
      UMask = "0007"; # So Caddy can access the Unix socket created by audiobookshelf.

      CapabilityBoundingSet = "";
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];

      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
    };

    users.users.${config.services.caddy.user}.extraGroups = [ config.services.audiobookshelf.group ];
  };
}
