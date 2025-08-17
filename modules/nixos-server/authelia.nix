{ config, lib, ... }:

let
  cfg = config.infra.authelia;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.authelia = {
    enable = lib.mkEnableOption "authelia";

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
      description = "Port Authelia listens on";
      default = 9091;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy :${builtins.toString cfg.port}
          '';
        };

        # Importable authentication block.
        extraConfig = ''
          (auth) {
            forward_auth :${builtins.toString config.infra.authelia.port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
            }
          }
        '';
      };

      authelia.instances.main = {
        enable = true;

        secrets = {
          jwtSecretFile = config.age.secrets.authelia-jwt-secret.path;
          sessionSecretFile = config.age.secrets.authelia-session-secret.path;
          storageEncryptionKeyFile = config.age.secrets.authelia-storage-encryption-key.path;
          oidcHmacSecretFile = config.age.secrets.authelia-oidc-hmac-secret.path;
          oidcIssuerPrivateKeyFile = config.age.secrets.authelia-oidc-issuer-private-key.path;
        };

        environmentVariables = {
          AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = config.age.secrets.authelia-postgres-password.path;
        };

        settings = {
          theme = "auto";
          log.level = "info";
          password_policy.zxcvbn.enabled = true;
          server.address = "tcp://:${builtins.toString cfg.port}/";

          notifier.filesystem.filename = "/var/lib/authelia-main/notifications.log";

          session.cookies = [
            {
              domain = cfg.hostDomain;
              authelia_url = "https://${domain}";
              default_redirection_url = "https://${cfg.hostDomain}";
            }
          ];

          storage.postgres = {
            address = "unix:///run/postgresql";
            database = "authelia-main";
            username = "authelia-main";
          };

          authentication_backend.file.path = config.age.secrets.authelia-users.path;

          access_control = {
            default_policy = "deny";

            rules = [
              {
                domain = cfg.hostDomain;
                policy = "one_factor";
                subject = [ "group:trusted-users" ];
              }
              {
                domain = "*.${cfg.hostDomain}";
                policy = "one_factor";
                subject = [ "group:trusted-users" ];
              }
            ];
          };
        };
      };

      postgresql = {
        enable = true;

        ensureDatabases = [
          "authelia-main"
        ];
        ensureUsers = [
          {
            name = "authelia-main";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd.services.authelia-main = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };
  };
}
