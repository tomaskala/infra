{ config, lib, ... }:

let
  cfg = config.infra.navidrome;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";

  user = "musicsync";
  group = "musicsync";
in
{
  options.infra.navidrome = {
    enable = lib.mkEnableOption "navidrome";

    hostDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this host";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain of this service";
    };

    musicDir = lib.mkOption {
      type = lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.path;
            description = "Directory where music is stored";
          };

          destination = lib.mkOption {
            type = lib.types.path;
            description = "Directory where music is periodically rsynced";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;
        openFirewall = false;

        settings = {
          Address = "unix:/run/navidrome/navidrome.sock";
          MusicFolder = cfg.musicDir.destination;
          AutoImportPlaylists = false;
          EnableCoverAnimation = false;
          EnableExternalServices = false;
          EnableGravatar = false;
          EnableStarRating = false;
          EnableTranscodingConfig = false;
          # Scan every day at 04:00 to run after sync.
          ScanSchedule = "0 4 * * *";
          ReverseProxyWhitelist = lib.mkIf config.infra.authelia.enable "@";
          EnableUserEditing = !config.infra.authelia.enable;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            ${lib.optionalString config.infra.authelia.enable "import auth"}
            reverse_proxy unix//run/navidrome/navidrome.sock
          '';
        };
      };

      rsync = {
        enable = true;

        jobs.music = {
          inherit user group;
          sources = [ cfg.musicDir.source ];
          inherit (cfg.musicDir) destination;

          settings = {
            archive = true;
            chmod = "D0755,F0644";
            chown = "${user}:${group}";
            human-readable = true;
            verbose = true;
          };

          timerConfig = {
            # Sync every day at 02:00 to run before scan.
            OnCalendar = "*-*-* 02:00:00";
            Persistent = true;
          };
        };
      };
    };

    users = {
      users = {
        ${user} = {
          inherit group;
          isSystemUser = true;
        };

        ${config.services.caddy.user}.extraGroups = [ config.services.navidrome.group ];
      };
      groups.${group} = { };
    };

    systemd.tmpfiles.settings.music.${cfg.musicDir.destination}.d = {
      inherit user group;
    };
  };
}
