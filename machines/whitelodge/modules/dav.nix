{ config, lib, ... }:

let
  cfg = config.services.dav;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.whitelodge;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  options.services.dav = {
    enable = lib.mkEnableOption "DAV server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain the DAV server is available on";
      example = "dav.home.arpa";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port the DAV server listens on";
      example = 5232;
    };
  };

  config = lib.mkIf cfg.enable {
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "localhost:${builtins.toString cfg.port}" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.age.secrets.radicale-htpasswd.path;
          htpasswd_encryption = "plain";
        };
        storage = {
          type = "multifilesystem";
          filesystem_folder = "/var/lib/radicale/collections";
        };
        web.type = "internal";
      };
    };

    services.caddy = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        listenAddresses = [
          gatewayCfg.internal.interface.ipv4
          "[${gatewayCfg.internal.interface.ipv6}]"
        ];

        extraConfig = ''
          tls internal

          encode {
            zstd
            gzip 5
          }

          @internal {
            remote_ip ${maskSubnet vpnSubnet.ipv4} ${maskSubnet vpnSubnet.ipv6}
          }

          handle @internal {
            reverse_proxy :${builtins.toString cfg.port}
          }

          respond "Access denied" 403 {
            close
          }
        '';
      };
    };

    networking.intranet.subnets.vpn.services.dav = {
      url = cfg.domain;
      inherit (gatewayCfg.internal.interface) ipv4 ipv6;
    };
  };
}
