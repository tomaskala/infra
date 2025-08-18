{ config, lib, ... }:

let
  cfg = config.infra.navidrome;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
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
      type = lib.types.path;
      description = "Where Navidrome stores the music";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;
        openFirewall = false;

        settings = {
          Address = "unix:/run/navidrome/navidrome.sock";
          MusicFolder = cfg.musicDir;
          AutoImportPlaylists = false;
          EnableCoverAnimation = false;
          EnableExternalServices = false;
          EnableGravatar = false;
          EnableStarRating = false;
          EnableTranscodingConfig = false;
          ScanSchedule = "@every 24h";
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
    };

    users.users.${config.services.caddy.user}.extraGroups = [ config.services.navidrome.group ];
  };
}
