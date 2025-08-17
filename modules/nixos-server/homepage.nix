{ config, lib, ... }:

let
  cfg = config.infra.homepage;
in
{
  options.infra.homepage = {
    enable = lib.mkEnableOption "homepage";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this machine";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      homepage-dashboard = {
        enable = true;
        openFirewall = false;
        allowedHosts = cfg.domain;

        settings = {
          title = "Bob";
          headerStyle = "boxed";
          base = cfg.domain;
          hideVersion = true;
          disableUpdateCheck = true;

          layout = {
            Media = {
              style = "row";
              columns = 3;
            };
          };
        };

        widgets = [
          {
            resources = {
              label = "system";
              cpu = true;
              memory = true;
              refresh = 5000;
            };
          }
          {
            resources = {
              label = "storage";
              disk = [ "/" ];
            };
          }
          {
            resources = {
              label = "uptime";
              uptime = true;
            };
          }
          {
            datetime = {
              text_size = "x1";
              format = {
                dateStyle = "long";
                timeStyle = "short";
                hour12 = false;
              };
            };
          }
        ];

        services = [
          {
            Media =
              (lib.optional config.infra.navidrome.enable {
                Navidrome = {
                  icon = "navidrome";
                  href = "https://${cfg.domain}/${config.infra.navidrome.matcher}";
                  description = "Music player";
                };
              })
              ++ (lib.optional config.infra.jellyfin.enable {
                Jellyfin = {
                  icon = "jellyfin";
                  href = "https://${cfg.domain}/${config.infra.jellyfin.matcher}";
                  description = "Media server";
                };
              });
          }
        ];
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          handle {
            ${lib.optionalString config.infra.authelia.enable "import auth"}
            reverse_proxy :${builtins.toString config.services.homepage-dashboard.listenPort}
          }
        '';
      };
    };
  };
}
