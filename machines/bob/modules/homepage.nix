{ config, lib, ... }:

let
  cfg = config.infra.homepage;
in
{
  options.infra.homepage = {
    enable = lib.mkEnableOption "homepage";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain homepage is available on";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      homepage-dashboard = {
        enable = true;
        openFirewall = false;
        environmentFile = config.age.secrets.homepage-env.path;

        settings = {
          title = "Welcome home";
          headerStyle = "boxed";
          hideVersion = true;
          disableUpdateCheck = true;

          layout = {
            Media = {
              style = "row";
              columns = 2;
            };
          };
        };

        widgets = [
          {
            search = {
              provider = "duckduckgo";
              target = "_blank";
            };
          }
          {
            resources = {
              label = "system";
              cpu = true;
              memory = true;
              uptime = true;
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
            openmeteo = {
              label = "Prague";
              timezone = "Europe/Prague";
              units = "metric";
              latitude = "{{HOMEPAGE_VAR_PRAGUE_LATITUDE}}";
              longitude = "{{HOMEPAGE_VAR_PRAGUE_LONGITUDE}}";
            };
          }
        ];

        services = [
          {
            Media =
              (lib.optional config.infra.calibre-web.enable {
                "Calibre" = {
                  icon = "calibre-web";
                  href = config.infra.calibre-web.domain;
                  description = "Ebook management";

                  widget = {
                    type = "calibreweb";
                    url = config.infra.calibre-web.domain;
                    username = "{{HOMEPAGE_VAR_CALIBRE_WEB_USERNAME}}";
                    password = "{{HOMEPAGE_VAR_CALIBRE_WEB_PASSWORD}}";
                  };
                };
              })
              ++ (lib.optional config.infra.navidrome.enable {
                "Navidrome" = {
                  icon = "navidrome";
                  href = config.infra.navidrome.domain;
                  description = "Music player";

                  widget = {
                    type = "navidrome";
                    url = config.infra.navidrome.domain;
                    user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
                    token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                    salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                  };
                };
              });
          }
        ];
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig =
          if config.infra.authentication.enable then
            ''
              forward_auth :${builtins.toString config.infra.authentication.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }

              reverse_proxy :${builtins.toString config.services.homepage-dashboard.listenPort}
            ''
          else
            ''
              reverse_proxy :${builtins.toString config.services.homepage-dashboard.listenPort}
            '';
      };
    };
  };
}
