{ config, lib, ... }:

let
  cfg = config.infra.authelia;
in
{
  options.infra.authelia = {
    enable = lib.mkEnableOption "authelia";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain protected by Authelia";
      example = "example.com";
    };

    matcher = lib.mkOption {
      type = lib.types.str;
      description = "Webserver matcher for this service";
      default = "auth";
      readOnly = true;
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

        virtualHosts.${cfg.domain}.extraConfig = ''
          @authelia path /${cfg.matcher} /${cfg.matcher}/*
          handle @authelia {
            reverse_proxy :${builtins.toString cfg.port}
          }
        '';

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
        };

        environmentVariables = {
          AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = config.age.secrets.authelia-postgres-password.path;
        };

        settings = {
          theme = "auto";
          log.level = "info";
          password_policy.zxcvbn.enabled = true;
          server.address = "tcp://127.0.0.1:${builtins.toString cfg.port}/${cfg.matcher}";

          notifier.filesystem.filename = "/var/lib/authelia-main/notifications.log";

          session.cookies = [
            {
              inherit (cfg) domain;
              authelia_url = "https://${cfg.domain}/${cfg.matcher}";
              default_redirection_url = "https://${cfg.domain}";
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
                inherit (cfg) domain;
                policy = "one_factor";
                subject = [ "group:trusted_users" ];
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
