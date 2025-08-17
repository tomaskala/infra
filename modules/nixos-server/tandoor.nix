{ config, lib, ... }:

let
  cfg = config.infra.tandoor;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.tandoor = {
    enable = lib.mkEnableOption "tandoor";

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
      tandoor-recipes = {
        enable = true;
        address = "localhost";

        extraConfig = {
          SECRET_KEY_FILE = config.age.secrets.tandoor-secret-key.path;
          ALLOWED_HOSTS = domain;
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_DB = "tandoor_recipes";
          POSTGRES_USER = "tandoor_recipes";
          REMOTE_USER_AUTH = 1;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            ${lib.optionalString config.infra.authelia.enable "import auth"}
            reverse_proxy :${builtins.toString config.services.tandoor-recipes.port}
          '';
        };
      };

      postgresql = {
        enable = true;

        ensureDatabases = [ "tandoor_recipes" ];
        ensureUsers = [
          {
            name = "tandoor_recipes";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd.services.tandoor-recipes = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };
  };
}
