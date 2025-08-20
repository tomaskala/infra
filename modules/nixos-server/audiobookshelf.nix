{ config, lib, ... }:

let
  cfg = config.infra.audiobookshelf;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.audiobookshelf = {
    enable = lib.mkEnableOption "audiobookshelf";

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
      audiobookshelf = {
        enable = true;
        openFirewall = false;
        host = "unix//run/audiobookshelf/audiobookshelf.sock";
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy unix//run/audiobookshelf/audiobookshelf.sock
          '';
        };
      };

      authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_name = "audiobookshelf";
          client_id = "loHBtDZmyZrON3H0DtuLwaoNOC0aEGydqQW2WLdam~z2aR8doXs40ew5LIsg8l0cAlIaA554";
          client_secret = "$pbkdf2-sha512$310000$dFQKDkvD0lWgCPAOQlw5Sg$PL1JKhX6whIx.CjvbLJUROysQlqzGv4BjdpwTspLA4ljG.wmcGQFqN2D387T309ba59bJ4umLhNg6OyeHqvKhA";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://${domain}/auth/openid/callback"
            "https://${domain}/auth/openid/mobile-redirect"
            "audiobookshelf://oauth"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];
    };

    systemd.services.audiobookshelf.serviceConfig.RuntimeDirectory = "audiobookshelf";
    users.users.${config.services.caddy.user}.extraGroups = [ config.services.audiobookshelf.group ];
  };
}
