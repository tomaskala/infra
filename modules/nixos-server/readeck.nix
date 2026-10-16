{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.readeck;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.readeck = {
    enable = lib.mkEnableOption "readeck";

    hostDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this host";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain of this service";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port Readeck listens on";
      default = 8000;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      readeck = {
        enable = true;
        package = pkgs.unstable.readeck;
        environmentFile = config.sops.secrets."readeck/env".path;

        settings = {
          server = {
            host = "127.0.0.1";
            inherit (cfg) port;
            trusted_proxies = [ "127.0.0.1" ];
          };

          database.source = "postgres://readeck@/readeck?host=/run/postgresql/";
          extractor.workers = 4;

          auth.oidc.providers = [
            {
              name = "Authelia";
              client_id = "DNJAfSRhH9GXr0I8KaeSZ9nyQFHD0hEay25CAjU_U_icLo93xkP4Hstv9mmHBL1c02VSSqKj";
              url = "https://${config.infra.authelia.subdomain}.${cfg.hostDomain}";
              provisioning = true;
            }
          ];
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy :${builtins.toString cfg.port}
          '';
        };
      };

      authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_name = "Readeck";
          client_id = "DNJAfSRhH9GXr0I8KaeSZ9nyQFHD0hEay25CAjU_U_icLo93xkP4Hstv9mmHBL1c02VSSqKj";
          client_secret = "$pbkdf2-sha512$310000$q1Wosyh2TUWeXB6bFjl1Bg$1fHywYv5Y2/L.kS2j65KDjR/f5emM/UyuSP69Js6RrFExZX0reuStyKn1zSzWfGYe9a53AXp5bY.SoG6l4kmjQ";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://${domain}/login/oidc"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      postgresql = {
        enable = true;

        ensureDatabases = [ "readeck" ];
        ensureUsers = [
          {
            name = "readeck";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd.services.readeck = {
      after = [ "postgresql.target" ];
      requires = [ "postgresql.target" ];

      serviceConfig = {
        User = "readeck";
        Group = "readeck";
      };
    };
  };
}
