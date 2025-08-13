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
                  href = "https://${cfg.domain}/${config.infra.calibre-web.matcher}";
                  description = "Ebook management";

                  widget = {
                    type = "calibreweb";
                    url = "https://${cfg.domain}/${config.infra.calibre-web.matcher}";
                    username = "{{HOMEPAGE_VAR_CALIBRE_WEB_USERNAME}}";
                    password = "{{HOMEPAGE_VAR_CALIBRE_WEB_PASSWORD}}";
                  };
                };
              })
              ++ (lib.optional config.infra.navidrome.enable {
                "Navidrome" = {
                  icon = "navidrome";
                  href = "https://${cfg.domain}/${config.infra.navidrome.matcher}";
                  description = "Music player";

                  widget = {
                    type = "navidrome";
                    url = "https://${cfg.domain}/${config.infra.navidrome.matcher}";
                    user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
                    token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                    salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                  };
                };
              });
          }
          {
            Misc = lib.optional config.infra.tandoor.enable {
              "Tandoor" = {
                icon = "tandoor-recipes";
                href = "https://${cfg.domain}/${config.infra.tandoor.matcher}";
                description = "Recipe management";

                widget = {
                  type = "tandoor";
                  url = "https://${cfg.domain}/${config.infra.tandoor.matcher}";
                  token = "{{HOMEPAGE_VAR_TANDOOR_TOKEN}}";
                };
              };
            };
          }
        ];
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          handle {
            ${lib.optionalString config.infra.authelia.enable ''
              forward_auth :${builtins.toString config.infra.authelia.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }
            ''}
            reverse_proxy :${builtins.toString config.services.homepage-dashboard.listenPort}
          }
        '';
      };
    };
  };
}
