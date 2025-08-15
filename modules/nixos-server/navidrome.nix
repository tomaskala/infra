{ config, lib, ... }:

let
  cfg = config.infra.navidrome;
in
{
  options.infra.navidrome = {
    enable = lib.mkEnableOption "navidrome";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this machine";
    };

    matcher = lib.mkOption {
      type = lib.types.str;
      description = "Webserver matcher for this service";
      default = "navidrome";
      readOnly = true;
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
          Address = "localhost";
          MusicFolder = cfg.musicDir;
          BaseUrl = "https://${cfg.domain}/${cfg.matcher}";
          AutoImportPlaylists = false;
          EnableExternalServices = false;
          EnableGravatar = false;
          EnableStarRating = false;
          EnableTranscodingConfig = false;
          ScanSchedule = "@every 24h";
          ReverseProxyWhitelist = lib.mkIf config.infra.authelia.enable "127.0.0.1/32";
          EnableUserEditing = !config.infra.authelia.enable;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          @navidrome path /${cfg.matcher} /${cfg.matcher}/*
          handle @navidrome {
            ${lib.optionalString config.infra.authelia.enable ''
              forward_auth :${builtins.toString config.infra.authelia.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }
            ''}
            reverse_proxy :${builtins.toString config.services.navidrome.settings.Port}
          }
        '';
      };
    };
  };
}
