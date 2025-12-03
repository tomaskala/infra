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
        database.createLocally = true;

        extraConfig = {
          SECRET_KEY_FILE = config.age.secrets.tandoor-secret-key.path;
          ALLOWED_HOSTS = domain;
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
    };
  };
}
