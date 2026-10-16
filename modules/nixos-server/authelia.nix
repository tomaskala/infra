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

    url = lib.mkOption {
      type = lib.types.str;
      description = "Authelia URL";
      default = "https://${domain}";
      readOnly = true;
    };

    clients = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }: {
            options = {
              clientName = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Client name, defaults to the key";
              };

              clientID = lib.mkOption {
                type = lib.types.str;
                description = "Unique identifier of the client";
              };

              clientSecret = lib.mkOption {
                type = lib.types.str;
                description = "pbkdf2 hash of the shared secret";
              };

              redirectURIs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "List of callbacks the client will redirect to";
              };

              extraSettings = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Additional free-form settings of the client";
              };
            };
          }
        )
      );
      description = "Attribute set of OIDC clients";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      # Source: <https://www.authelia.com/configuration/methods/secrets/#environment-variables>.
      "authelia/jwt-secret" = {
        mode = "0400";
        owner = "authelia-main";
      };
      "authelia/session-secret" = {
        mode = "0400";
        owner = "authelia-main";
      };
      "authelia/storage-encryption-key" = {
        mode = "0400";
        owner = "authelia-main";
      };
      "authelia/oidc/hmac-secret" = {
        mode = "0400";
        owner = "authelia-main";
      };
      "authelia/oidc/issuer-private-key" = {
        mode = "0400";
        owner = "authelia-main";
      };
      "authelia/users" = {
        mode = "0400";
        owner = "authelia-main";
      };
    };

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
            forward_auth {args[0]} :${builtins.toString config.infra.authelia.port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
            }
          }
        '';
      };

      authelia.instances.main = {
        enable = true;

        secrets = {
          jwtSecretFile = config.sops.secrets."authelia/jwt-secret".path;
          sessionSecretFile = config.sops.secrets."authelia/session-secret".path;
          storageEncryptionKeyFile = config.sops.secrets."authelia/storage-encryption-key".path;
          oidcHmacSecretFile = config.sops.secrets."authelia/oidc/hmac-secret".path;
          oidcIssuerPrivateKeyFile = config.sops.secrets."authelia/oidc/issuer-private-key".path;
        };

        settings = {
          theme = "auto";
          log.level = "info";
          password_policy.zxcvbn.enabled = true;
          server.address = "tcp://127.0.0.1:${builtins.toString cfg.port}/";

          notifier.filesystem.filename = "/var/lib/authelia-main/notifications.log";

          session = {
            redis.host = config.services.redis.servers.authelia.unixSocket;

            cookies = [
              {
                domain = cfg.hostDomain;
                authelia_url = "https://${domain}";
                default_redirection_url = "https://${cfg.hostDomain}";
                inactivity = "1h";
                expiration = "1d";
                remember_me = "3M";
              }
            ];
          };

          storage.postgres = {
            address = "unix:///run/postgresql";
            database = "authelia-main";
            username = "authelia-main";
          };

          authentication_backend = {
            file.path = config.sops.secrets."authelia/users".path;
            password_reset.disable = true;
            password_change.disable = true;
          };

          access_control = {
            default_policy = "deny";

            rules = [
              {
                domain = [
                  cfg.hostDomain
                  "*.${cfg.hostDomain}"
                ];
                policy = "one_factor";
                subject = [ "group:trusted-users" ];
              }
            ];
          };

          identity_providers.oidc.clients = lib.mapAttrsToList (
            _: c:
            {
              client_name = c.clientName;
              client_id = c.clientID;
              client_secret = c.clientSecret;
              redirect_uris = c.redirectURIs;

              authorization_policy = "one_factor";
              require_pkce = true;
              pkce_challenge_method = "S256";
            }
            // c.extraSettings
          ) cfg.clients;
        };
      };

      postgresql = {
        enable = true;

        ensureDatabases = [ "authelia-main" ];
        ensureUsers = [
          {
            name = "authelia-main";
            ensureDBOwnership = true;
          }
        ];
      };

      redis.servers.authelia = {
        enable = true;
        port = 0;
        unixSocketPerm = 600;
        inherit (config.services.authelia.instances.main) user group;
      };
    };

    systemd.services.authelia-main = {
      after = [
        "postgresql.target"
        "redis-authelia.service"
      ];
      requires = [
        "postgresql.target"
        "redis-authelia.service"
      ];
    };
  };
}
