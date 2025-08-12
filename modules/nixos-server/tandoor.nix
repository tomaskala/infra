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
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_DB = "tandoor";
          POSTGRES_USER = "tandoor";
        };
      };

      # TODO: Remote auth.
      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
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
