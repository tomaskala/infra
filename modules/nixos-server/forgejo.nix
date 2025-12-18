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
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo = {
        enable = true;
        database.type = "postgres";

        settings = {
          server = {
            DOMAIN = domain;
            ROOT_URL = "https://${domain}/";
            PROTOCOL = "http+unix";
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

      openssh.settings.AcceptEnv = "GIT_PROTOCOL";

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy unix/${config.services.forgejo.settings.server.HTTP_ADDR}
          '';
        };
      };

      authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_name = "Forgejo";
          client_id = "H0RNuqVg7fyYtN4uBBmmMkh2zOMZpmpab.vjDUZV9ApHDaUw34rvOL5Glr5q66wB26WZxrm4";
          client_secret = "$pbkdf2-sha512$310000$VTVtASSZAHN8N3TpwBrG1g$KIVLy.ncnNs51vhe/vtREpRE.SLUwYG3Cqsde4sw/iBXnl/GfltlZpW0THtmQVed4N5DEwXWonD9FuF4YN6Q1g";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://${domain}/user/oauth2/authelia/callback"
          ];
          scopes = [
            "openid"
            "email"
            "profile"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];
    };

    users.users.${config.services.caddy.user}.extraGroups = [ config.services.forgejo.group ];
  };
}
