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
            admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
            secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";
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
            client_id = config.infra.authelia.clients.grafana.clientID;
            client_secret = "$__file{${config.sops.secrets."grafana/authelia-password".path}}";
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            empty_scopes = false;
            auth_url = "${config.infra.authelia.url}/api/oidc/authorization";
            token_url = "${config.infra.authelia.url}/api/oidc/token";
            api_url = "${config.infra.authelia.url}/api/oidc/userinfo";
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

      authelia.instances.main.settings.identity_providers.oidc.claims_policies.grafana.id_token = [
        "email"
        "name"
        "groups"
        "preferred_username"
      ];
    };

    infra.authelia.clients.grafana = {
      clientID = "h5Xt~Om3pMxHznELCoQLMh4291GNkpr~shG6t5yv5Cu19LajdJmTfUCTKXJ_QAkELHHaE8f-";
      clientSecret = "$pbkdf2-sha512$310000$/YZi4RumA3MyHwCmJrqATg$xeiI7.1vOCS0IiFXNy9EWS87Ny4.JaWOKkOtAa2NcTBqJaXrl9t.94tGzqXXnmVkHSrV0aK77mHCSkZ9BeEgXA";
      redirectURIs = [
        "https://${domain}/login/generic_oauth"
      ];
      extraSettings.claims_policy = "grafana";
    };

    users.users.${config.services.caddy.user}.extraGroups = [ "grafana" ];
  };
}
