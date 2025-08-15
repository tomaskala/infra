{ config, lib, ... }:

let
  cfg = config.infra.tandoor;
in
{
  options.infra.tandoor = {
    enable = lib.mkEnableOption "tandoor";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this machine";
    };

    matcher = lib.mkOption {
      type = lib.types.str;
      description = "Webserver matcher for this service";
      default = "tandoor";
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tandoor-recipes = {
        enable = true;
        address = "localhost";

        extraConfig = {
          SECRET_KEY_FILE = config.age.secrets.tandoor-secret-key.path;
          ALLOWED_HOSTS = cfg.domain;
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_DB = "tandoor_recipes";
          POSTGRES_USER = "tandoor_recipes";
          REMOTE_USER_AUTH = 1;
          STATIC_URL = "https://${cfg.domain}/${cfg.matcher}/static/";
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          @tandoor path /${cfg.matcher} /${cfg.matcher}/*
          handle @tandoor {
            ${lib.optionalString config.infra.authelia.enable ''
              forward_auth :${builtins.toString config.infra.authelia.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }
            ''}
            reverse_proxy :${builtins.toString config.services.tandoor-recipes.port}
        '';
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
