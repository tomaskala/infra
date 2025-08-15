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
              (lib.optional config.infra.calibre-web.enable {
                Calibre = {
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
                Navidrome = {
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
              })
              ++ (lib.optional config.infra.jellyfin.enable {
                Jellyfin = {
                  icon = "jellyfin";
                  href = "https://${cfg.domain}/${config.infra.jellyfin.matcher}";
                  description = "Media server";

                  widget = {
                    type = "jellyfin";
                    url = "https://${cfg.domain}/${config.infra.jellyfin.matcher}";
                    key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                    enableBlocks = true;
                    enableNowPlaying = false;
                  };
                };
              });
          }
          {
            Misc = lib.optional config.infra.tandoor.enable {
              Tandoor = {
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
