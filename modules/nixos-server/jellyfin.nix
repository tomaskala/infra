{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.jellyfin;
in
{
  options.infra.jellyfin = {
    enable = lib.mkEnableOption "jellyfin";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this machine";
    };

    matcher = lib.mkOption {
      type = lib.types.str;
      description = "Webserver matcher for this service";
      default = "jellyfin";
      readOnly = true;
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Jellyfin HTTP port is not configurable using Nix";
      default = 8096;
      readOnly = true;
    };
  };

  # When setting up Jellyfin for the first time, it's necessary to open firewall, connect directly
  # to the Jellyfin instance, go to the network settings, and set the base URL field to "cfg.matcher"
  # (without the quotes, without leading or trailing slashes). Afterwards, restart the service and
  # proxied connection should work.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    services = {
      jellyfin = {
        enable = true;
        openFirewall = false;
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          @jellyfin path /${cfg.matcher} /${cfg.matcher}/*
          handle @jellyfin {
            reverse_proxy :${builtins.toString cfg.port}
          }
        '';
      };
    };

    systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

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
