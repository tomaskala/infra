{ config, lib, ... }:

let
  cfg = config.infra.paperless;
  domain = "${cfg.subdomain}.${cfg.hostDomain}";
in
{
  options.infra.paperless = {
    enable = lib.mkEnableOption "paperless";

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
      paperless = {
        enable = true;
        inherit domain;
        database.createLocally = true;
        environmentFile = config.age.secrets.paperless-env.path;
        passwordFile = config.age.secrets.paperless-admin-password.path;
        configureNginx = false;
        configureTika = false;

        settings = {
          PAPERLESS_ADMIN_USER = "admin";
          # Czech+English
          PAPERLESS_OCR_LANGUAGE = "ces+eng";
          # Use the web UI for uploading documents.
          PAPERLESS_CONSUMER_DISABLE = true;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${domain} = {
          useACMEHost = cfg.hostDomain;
          extraConfig = ''
            reverse_proxy :${builtins.toString config.services.paperless.port}
          '';
        };
      };

      authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_name = "Paperless";
          client_id = "uyC3mXDzLEuj8EAplmTmgAhYvJAmGDcARmenl.bT50tKOWgA.ZtI.nkHeo6Iwvgst4eXONJo";
          client_secret = "$pbkdf2-sha512$310000$mPqgYLGej6L27kI5mxAwqQ$xRaH2f8b7RNhmGHvNXBoAZrebirdLAspLVWV2byDLFKyNqhuHE1wHEg3/WCIGW8pXvndBBsltqzTUeAe5iW6hA";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://${domain}/accounts/oidc/authelia/login/callback/"
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
  };
}
