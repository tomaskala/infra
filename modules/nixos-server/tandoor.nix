{ config, lib, ... }:

let
  cfg = config.infra.tandoor;
in
{
  options.infra.tandoor = {
    enable = lib.mkEnableOption "tandoor";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain Tandoor is available on";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tandoor-recipes = {
        enable = true;
        address = "localhost";

        extraConfig = {
          SECRET_KEY_FILE = ""; # TODO
          ALLOWED_HOSTS = cfg.domain;
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_DB = "tandoor";
          POSTGRES_USER = "tandoor";
          REMOTE_USER_AUTH = 1;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig =
          if config.infra.authentication.enable then
            ''
              forward_auth :${builtins.toString config.infra.authentication.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }

              reverse_proxy :${builtins.toString config.services.tandoor-recipes.port}
            ''
          else
            ''
              reverse_proxy :${builtins.toString config.services.tandoor-recipes.port}
            '';
      };

      postgresql = {
        enable = true;

        ensureDatabases = [ "tandoor" ];
        ensureUsers = [
          {
            name = "tandoor";
            ensureDBOwnership = true;
          }
        ];
      };
    };
  };
}
