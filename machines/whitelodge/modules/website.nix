{ config, lib, ... }:

let
  cfg = config.services.website;
  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.whitelodge;
in {
  options.services.website = {
    enable = lib.mkEnableOption "website";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain the website is available on";
      example = "example.com";
    };

    webroot = lib.mkOption {
      type = lib.types.path;
      description = "Root path of the site";
      example = "/var/www/example.com";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "ACME account email address";
      example = "acme@example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;

      virtualHosts.${cfg.domain} = {
        extraConfig = ''
          root * ${cfg.webroot}
          encode gzip
          file_server

          header {
            # Disable FLoC tracking.
            Permissions-Policy interest-cohort=()

            # Enable HSTS.
            Strict-Transport-Security max-age=31536000

            # Disable clients from sniffing the media type.
            X-Content-Type-Options nosniff

            # Clickjacking protection.
            X-Frame-Options DENY

            # Keep referrer data off third parties.
            Referrer-Policy same-origin

            # Content should come from the site's origin (excludes subdomains).
            # Prevent the framing of this site by other sites.
            Content-Security-Policy "default-src 'self'; frame-ancestors 'none'"
          }
        '';
      };
    };

    services.unbound = {
      enable = true;
      localDomains.${cfg.domain} = {
        inherit (peerCfg.internal.interface) ipv4 ipv6;
      };
    };
  };
}