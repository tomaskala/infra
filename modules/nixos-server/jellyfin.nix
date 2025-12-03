{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.jellyfin;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.jellyfin = {
    enable = lib.mkEnableOption "jellyfin";

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
      jellyfin = {
        enable = true;
        openFirewall = false;
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy unix//run/jellyfin/jellyfin.sock
          '';
        };
      };
    };

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
    systemd.services.jellyfin = {
      serviceConfig.RuntimeDirectory = "jellyfin";

      environment = {
        LIBVA_DRIVER_NAME = "iHD";
        JELLYFIN_kestrel__socket = "true";
        JELLYFIN_kestrel__socketPath = "/run/jellyfin/jellyfin.sock";
        JELLYFIN_kestrel__socketPermissions = "0660";
      };
    };

    users.users.${config.services.caddy.user}.extraGroups = [ config.services.jellyfin.group ];

    hardware.graphics = {
      enable = true;

      extraPackages = with pkgs; [
        intel-media-driver
        libva-vdpau-driver
        intel-compute-runtime
        vpl-gpu-rt
        intel-ocl
      ];
    };
  };
}
