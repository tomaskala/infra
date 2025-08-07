{ config, lib, ... }:

let
  cfg = config.infra.navidrome;
in
{
  options.infra.navidrome = {
    enable = lib.mkEnableOption "navidrome";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain Navidrome is available on";
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
          AutoImportPlaylists = false;
          EnableExternalServices = false;
          EnableGravatar = false;
          EnableStarRating = false;
          EnableTranscodingConfig = false;
          ScanSchedule = "@every 24h";
          EnableUserEditing = !config.infra.authentication.enable;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig =
          if config.infra.authentication.enable then
            ''
              @protected not path /share/* /rest/*
              forward_auth @protected :${builtins.toString config.infra.authentication.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }

              reverse_proxy :${builtins.toString config.services.navidrome.settings.Port}
            ''
          else
            ''
              reverse_proxy :${builtins.toString config.services.navidrome.settings.Port}
            '';
      };
    };
  };
}
