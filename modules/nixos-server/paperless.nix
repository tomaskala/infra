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
    sops.secrets = {
      "paperless/admin-password" = { };
      "paperless/env" = { };
    };

    services = {
      paperless = {
        enable = true;
        inherit domain;
        database.createLocally = true;
        environmentFile = config.sops.secrets."paperless/env".path;
        passwordFile = config.sops.secrets."paperless/admin-password".path;
        configureNginx = false;
        configureTika = false;

        settings = {
          PAPERLESS_ADMIN_USER = "admin";
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
    };

    infra.authelia.clients.paperless = {
      clientID = "uyC3mXDzLEuj8EAplmTmgAhYvJAmGDcARmenl.bT50tKOWgA.ZtI.nkHeo6Iwvgst4eXONJo";
      clientSecret = "$pbkdf2-sha512$310000$ayNWr2ery275IsGs7DHPdg$tvnnquP6d8M2mX8Ve9ipWziz8QoTsvlbXnlaOjtCRnaQsKdzt8iz/TNlpPQ1QpY3umriWrOqKKvhtYipnR8BmA";
      redirectURIs = [
        "https://${domain}/accounts/oidc/authelia/login/callback/"
      ];
    };
  };
}
