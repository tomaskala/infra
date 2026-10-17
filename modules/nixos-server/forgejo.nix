{ config, lib, ... }:

let
  cfg = config.infra.forgejo;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.forgejo = {
    enable = lib.mkEnableOption "forgejo";

    hostDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this host";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain of this service";
    };

    url = lib.mkOption {
      type = lib.types.str;
      description = "URL of this service";
      default = "https://${domain}";
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo = {
        enable = true;
        database.type = "postgres";

        settings = {
          server = {
            DOMAIN = domain;
            ROOT_URL = cfg.url;
            PROTOCOL = "http+unix";
            SSH_PORT = lib.head config.services.openssh.ports;
          };

          cache = {
            ADAPTER = "twoqueue";
            HOST = ''{"size":100, "recent_ratio":0.25, "ghost_ratio":0.5}'';
          };

          openid = {
            ENABLE_OPENID_SIGNIN = false;
            ENABLE_OPENID_SIGNUP = true;
            WHITELISTED_URIS = "${config.infra.authelia.subdomain}.${config.infra.authelia.hostDomain}";
          };

          service = {
            DISABLE_REGISTRATION = false;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
          };
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy unix/${config.services.forgejo.settings.server.HTTP_ADDR}
          '';
        };
      };
    };

    infra.authelia.clients.forgejo = {
      clientID = "H0RNuqVg7fyYtN4uBBmmMkh2zOMZpmpab.vjDUZV9ApHDaUw34rvOL5Glr5q66wB26WZxrm4";
      clientSecret = "$pbkdf2-sha512$310000$Qrl8CXrZ3fmnyqfrOhKeow$2.S2NjnkKFYrHoaqXMZwZBCzL2VWMHS7YLMx3qO/zLbJLpQfLkijJ4RzFhSBydH7x5VLFnsv7vQnfceYb0WxBQ";
      redirectURIs = [
        "${cfg.url}/user/oauth2/authelia/callback"
      ];
    };

    users.users.${config.services.caddy.user}.extraGroups = [ config.services.forgejo.group ];
  };
}
