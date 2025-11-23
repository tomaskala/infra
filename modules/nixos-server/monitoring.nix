{ config, lib, ... }:

let
  cfg = config.infra.monitoring;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.monitoring = {
    enable = lib.mkEnableOption "monitoring";

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
      grafana = {
        enable = true;

        provision = {
          enable = true;

          datasources.settings = {
            prune = true;

            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                access = "proxy";
                url = "http://127.0.0.1:${builtins.toString config.services.prometheus.port}";
              }
            ];
          };
        };

        settings = {
          server = {
            root_url = "https://${domain}";
            protocol = "socket";
            enable_gzip = true;
          };

          database = {
            type = "postgres";
            host = "/run/postgresql";
            user = "grafana";
          };

          analytics = {
            reporting_enabled = false;
            feedback_links_enabled = false;
            check_for_updates = false;
            check_for_plugin_updates = false;
          };

          security = {
            admin_user = "admin";
            admin_password = "$__file{${config.age.secrets.grafana-admin-password.path}}";
            disable_gravatar = true;
          };

          users = {
            default_theme = "system";
            default_language = "detect";
          };

          "auth.generic_oauth" = {
            enabled = true;
            name = "Authelia";
            icon = "signin";
            client_id = "h5Xt~Om3pMxHznELCoQLMh4291GNkpr~shG6t5yv5Cu19LajdJmTfUCTKXJ_QAkELHHaE8f-";
            client_secret = "$__file{${config.age.secrets.grafana-authelia-password.path}}";
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            empty_scopes = false;
            auth_url = "https://${config.infra.authelia.subdomain}.${cfg.hostDomain}/api/oidc/authorization";
            token_url = "https://${config.infra.authelia.subdomain}.${cfg.hostDomain}/api/oidc/token";
            api_url = "https://${config.infra.authelia.subdomain}.${cfg.hostDomain}/api/oidc/userinfo";
            login_attribute_path = "preferred_username";
            groups_attribute_path = "groups";
            name_attribute_path = "name";
            use_pkce = true;
            role_attribute_path = "contains(groups, 'grafana_admin') && 'Admin' || 'Viewer'";
          };
        };
      };

      postgresql = {
        enable = true;

        ensureDatabases = [ "grafana" ];
        ensureUsers = [
          {
            name = "grafana";
            ensureDBOwnership = true;
          }
        ];
      };

      prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy unix/${config.services.grafana.settings.server.socket}
          '';
        };
      };

      authelia.instances.main.settings.identity_providers.oidc = {
        claims_policies.grafana.id_token = [
          "email"
          "name"
          "groups"
          "preferred_username"
        ];

        clients = [
          {
            client_name = "Grafana";
            client_id = "h5Xt~Om3pMxHznELCoQLMh4291GNkpr~shG6t5yv5Cu19LajdJmTfUCTKXJ_QAkELHHaE8f-";
            client_secret = "$pbkdf2-sha512$310000$hQ0qGqpskj7tgSaVvDjY5A$nA9BBEvndooWYyM.6LFvoDzHWNc5lm/PqLcKlkTgA00g57IurTmWDNCg165RhTs9lqh.IL52/LrL3E5K74J1Ug";
            claims_policy = "grafana";
            public = false;
            authorization_policy = "one_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://${domain}/login/generic_oauth"
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
      };
    };

    users.users.${config.services.caddy.user}.extraGroups = [ "grafana" ];
  };
}
