{ config, lib, ... }:

let
  cfg = config.infra.homepage;
in
{
  options.infra.homepage = {
    enable = lib.mkEnableOption "homepage";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this service";
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
              (lib.optional config.infra.kavita.enable {
                Kavita = {
                  icon = "kavita";
                  href = "https://${config.infra.kavita.domain}";
                  description = "Ebook library";
                };
              })
              ++ (lib.optional config.infra.navidrome.enable {
                Navidrome = {
                  icon = "navidrome";
                  href = "https://${config.infra.navidrome.domain}";
                  description = "Music player";
                };
              })
              ++ (lib.optional config.infra.jellyfin.enable {
                Jellyfin = {
                  icon = "jellyfin";
                  href = "https://${config.infra.jellyfin.domain}";
                  description = "Media server";
                };
              });
          }
          {
            Misc = lib.optional config.infra.tandoor.enable {
              Tandoor = {
                icon = "tandoor-recipes";
                href = "https://${cfg.domain}/${config.infra.tandoor.matcher}";
                description = "Recipe management";
              };
            };
          }
        ];
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          ${lib.optionalString config.infra.authelia.enable "import auth"}
          reverse_proxy :${builtins.toString config.services.homepage-dashboard.listenPort}
        '';
      };
    };
  };
}
