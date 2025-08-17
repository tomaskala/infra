{ config, lib, ... }:

let
  cfg = config.infra.navidrome;
in
{
  options.infra.navidrome = {
    enable = lib.mkEnableOption "navidrome";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this service";
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
          ReverseProxyWhitelist = lib.mkIf config.infra.authelia.enable "127.0.0.1/32";
          EnableUserEditing = !config.infra.authelia.enable;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          ${lib.optionalString config.infra.authelia.enable "import auth"}
          reverse_proxy :${builtins.toString config.services.navidrome.settings.Port}
        '';
      };
    };
  };
}
