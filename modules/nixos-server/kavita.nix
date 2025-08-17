{ config, lib, ... }:

let
  cfg = config.infra.kavita;
in
{
  options.infra.kavita = {
    enable = lib.mkEnableOption "kavita";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this service";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      kavita = {
        enable = true;
        tokenKeyFile = config.age.secrets.kavita-token-key.path;
        settings.IpAddresses = "127.0.0.1,::1";
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          reverse_proxy :${builtins.toString config.services.kavita.settings.Port}
        '';
      };
    };
  };
}
