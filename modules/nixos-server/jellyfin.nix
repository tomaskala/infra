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

      authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_name = "Jellyfin";
          client_id = "ak1uYO_QiSPnWCDYE2.7ou8dJpuzMSn.zheGGtxHAO-h6d5GLYMRTNVTq~wefxTZ9bHKIBWJ";
          client_secret = "$pbkdf2-sha512$310000$WVcn/7wPDz6GkNCIof9BVg$3Px.2hEpdEQWdE5cNyZyCw54JAZ9fvyh7b6KJJpqYUw4QsxsJ0lStggIQ7.DpSRy4NhN84NHRO0SjsiZsVJaGg";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://${cfg.domain}/${cfg.matcher}/sso/OID/redirect/authelia"
            "http://${cfg.domain}/${cfg.matcher}/sso/OID/redirect/authelia"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
      ];
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
