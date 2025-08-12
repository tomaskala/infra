{ config, lib, ... }:

let
  cfg = config.infra.tandoor;
in
{
  options.infra.tandoor = {
    enable = lib.mkEnableOption "tandoor";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain Tandoor is available on";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tandoor-recipes = {
        enable = true;
        address = "localhost";

        extraConfig = {
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_DB = "tandoor";
          POSTGRES_USER = "tandoor";
          SOCIALACCOUNT_PROVIDERS_FILE = config.age.secrets.tandoor-socialaccount-providers.path;
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          reverse_proxy :${builtins.toString config.services.tandoor-recipes.port}
        '';
      };

      postgresql = {
        enable = true;

        ensureDatabases = [ "tandoor" ];
        ensureUsers = [
          {
            name = "tandoor";
            ensureDBOwnership = true;
          }
        ];
      };

      authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "iEAiXLq8fs2qQRIg193Rtjle7ZxyH6JLh06R1tQQe9AURyvCBGdG-T5Xs0tqfEC0fbNZBB4O";
          client_name = "Tandoor";
          client_secret = "$pbkdf2-sha512$310000$5pPJa9R4gV4.V38WAyOOQw$ISDswA9VzQ.Klz80AZgZyOWWtqQYfW55xK5G.IzV/HJYLK8W6dXHyYjDT0nJPJ4w..CVWgZRcDj3t0tCAz.T1Q";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = false;
          pkce_challenge_methods = "";
          redirect_uris = [
            "https://${cfg.domain}/accounts/oidc/authelia/login/callback/"
          ];
          scopes = [
            "openid"
            "profile"
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
