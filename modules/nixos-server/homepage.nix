{ config, lib, ... }:

let
  cfg = config.infra.homepage;
in
{
  options.infra.homepage = {
    enable = lib.mkEnableOption "homepage";

    hostDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this host";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      homepage-dashboard = {
        enable = true;
        openFirewall = false;
        allowedHosts = cfg.hostDomain;

        settings = {
          title = "Bob";
          headerStyle = "boxed";
          target = "_self";
          base = cfg.hostDomain;
          hideVersion = true;
          disableUpdateCheck = true;

          layout = {
            Media = {
              style = "row";
              columns = 3;
            };
            Misc = {
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
              (lib.optional config.infra.audiobookshelf.enable {
                audiobookshelf = {
                  icon = "audiobookshelf";
                  href = "https://${config.infra.audiobookshelf.subdomain}.${cfg.hostDomain}";
                  description = "Audiobook & ebook management";
                };
              })
              ++ (lib.optional config.infra.navidrome.enable {
                Navidrome = {
                  icon = "navidrome";
                  href = "https://${config.infra.navidrome.subdomain}.${cfg.hostDomain}";
                  description = "Music player";
                };
              })
              ++ (lib.optional config.infra.jellyfin.enable {
                Jellyfin = {
                  icon = "jellyfin";
                  href = "https://${config.infra.jellyfin.subdomain}.${cfg.hostDomain}";
                  description = "Media server";
                };
              });
          }
          {
            Misc =
              (lib.optional config.infra.monitoring.enable {
                Grafana = {
                  icon = "grafana";
                  href = "https://${config.infra.monitoring.subdomain}.${cfg.hostDomain}";
                  description = "Monitoring";
                };
              })
              ++ (lib.optional config.infra.readeck.enable {
                Readeck = {
                  icon = "readeck";
                  href = "https://${config.infra.readeck.subdomain}.${cfg.hostDomain}";
                  description = "Read later";
                };
              })
              ++ (lib.optional config.infra.tandoor.enable {
                Tandoor = {
                  icon = "tandoor-recipes";
                  href = "https://${config.infra.tandoor.subdomain}.${cfg.hostDomain}";
                  description = "Recipe management";
                };
              });
          }
        ];
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.hostDomain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            ${lib.optionalString config.infra.authelia.enable "import auth"}
            reverse_proxy :${builtins.toString config.services.homepage-dashboard.listenPort}
          '';
        };
      };
    };
  };
}
