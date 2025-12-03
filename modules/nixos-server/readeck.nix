{ config, lib, ... }:

let
  cfg = config.infra.readeck;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.readeck = {
    enable = lib.mkEnableOption "readeck";

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
      description = "Port Readeck listens on";
      default = 8000;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      readeck = {
        enable = true;
        environmentFile = config.age.secrets.readeck-env.path;

        settings = {
          server = {
            host = "127.0.0.1";
            inherit (cfg) port;
            trusted_proxies = [ "127.0.0.1" ];
          };

          database.source = "postgres://readeck@/readeck?host=/run/postgresql/";
          extractor.workers = 4;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy :${builtins.toString cfg.port}
          '';
        };
      };

      postgresql = {
        enable = true;

        ensureDatabases = [ "readeck" ];
        ensureUsers = [
          {
            name = "readeck";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd.services.readeck = {
      after = [ "postgresql.target" ];
      requires = [ "postgresql.target" ];

      serviceConfig = {
        User = "readeck";
        Group = "readeck";
      };
    };
  };
}
