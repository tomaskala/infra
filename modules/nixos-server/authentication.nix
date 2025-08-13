{ config, lib, ... }:

let
  cfg = config.infra.authentication;
  autheliaDomain = "${cfg.subdomains.auth}.${cfg.baseDomain}";
in
{
  options.infra.authentication = {
    enable = lib.mkEnableOption "authentication";

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port Authelia listens on";
      default = 9091;
      readOnly = true;
    };

    subdomains = lib.mkOption {
      type = lib.types.submodule {
        options = {
          auth = lib.mkOption {
            type = lib.types.str;
            description = "Authelia subdomain of the base domain";
            example = "auth";
          };

          ldap = lib.mkOption {
            type = lib.types.str;
            description = "LDAP subdomain of the base domain";
            example = "ldap";
          };
        };
      };
    };

    baseDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain protected by Authelia";
      example = "example.com";
    };

    ldapBaseDN = lib.mkOption {
      type = lib.types.str;
      description = "LDAP base distinguished name";
      example = "dc=example,dc=com";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      caddy = {
        enable = true;

        virtualHosts.${autheliaDomain}.extraConfig = ''
          reverse_proxy :${builtins.toString cfg.port}
        '';

        virtualHosts."${cfg.subdomains.ldap}.${cfg.baseDomain}".extraConfig = ''
          reverse_proxy :${builtins.toString config.services.lldap.settings.http_port}
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
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.authelia-ldap-password.path;
          AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = config.age.secrets.authelia-postgres-password.path;
        };

        settings = {
          theme = "auto";
          log.level = "info";
          password_policy.zxcvbn.enabled = true;
          server.address = "tcp://127.0.0.1:${builtins.toString cfg.port}/";

          notifier.filesystem.filename = "/var/lib/authelia-main/notifications.log";

          session.cookies = [
            {
              domain = cfg.baseDomain;
              authelia_url = "https://${autheliaDomain}";
              default_redirection_url = "https://${cfg.baseDomain}";
            }
          ];

          storage.postgres = {
            address = "unix:///run/postgresql";
            database = "authelia-main";
            username = "authelia-main";
          };

          authentication_backend.ldap = {
            implementation = "lldap";
            address = "ldap://localhost:${builtins.toString config.services.lldap.settings.ldap_port}";
            base_dn = cfg.ldapBaseDN;
            user = "uid=authelia,ou=people,${cfg.ldapBaseDN}";
          };

          access_control = {
            default_policy = "deny";

            rules = [
              {
                domain = cfg.baseDomain;
                policy = "one_factor";
                subject = [ "group:trusted_users" ];
              }
            ];
          };
        };
      };

      lldap = {
        enable = true;

        settings = {
          database_url = "postgresql:///lldap?host=/run/postgresql";
          http_url = "https://${cfg.subdomains.ldap}.${cfg.baseDomain}";
          ldap_base_dn = cfg.ldapBaseDN;
        };

        environment = {
          LLDAP_JWT_SECRET_FILE = "%d/jwt-secret.key";
          LLDAP_LDAP_USER_PASS_FILE = "%d/user-pass.key";
        };
      };

      postgresql = {
        enable = true;

        ensureDatabases = [
          "authelia-main"
          "lldap"
        ];
        ensureUsers = [
          {
            name = "authelia-main";
            ensureDBOwnership = true;
          }
          {
            name = "lldap";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd.services = {
      authelia-main = {
        after = [
          "lldap.service"
          "postgresql.service"
        ];
        requires = [
          "lldap.service"
          "postgresql.service"
        ];
      };

      lldap = {
        after = [
          "postgresql.service"
          "caddy.service" # So that TLS certificates have been created.
        ];
        requires = [ "postgresql.service" ];

        # Needed because the service uses dynamic users, so we can't assign ownership
        # to the age secrets directly.
        serviceConfig.LoadCredential = [
          "jwt-secret.key:${config.age.secrets.lldap-jwt-secret.path}"
          "user-pass.key:${config.age.secrets.authelia-ldap-password.path}"
        ];
      };
    };
  };
}
