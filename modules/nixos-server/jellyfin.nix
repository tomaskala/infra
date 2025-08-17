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

    port = lib.mkOption {
      type = lib.types.port;
      description = "Jellyfin HTTP port is not configurable using Nix";
      default = 8096;
      readOnly = true;
    };
  };

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

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy :${builtins.toString cfg.port}
          '';
        };
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
            "https://${domain}/sso/OID/redirect/authelia"
            "http://${domain}/sso/OID/redirect/authelia"
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
