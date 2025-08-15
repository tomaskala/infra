{ config, lib, ... }:

let
  cfg = config.infra.calibre-web;
in
{
  options.infra.calibre-web = {
    enable = lib.mkEnableOption "calibre-web";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of this machine";
    };

    matcher = lib.mkOption {
      type = lib.types.str;
      description = "Webserver matcher for this service";
      default = "calibre-web";
      readOnly = true;
    };

    libraryDir = lib.mkOption {
      type = lib.types.path;
      description = "Where Calibre stores the ebooks";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      calibre-web = {
        enable = true;
        listen.ip = "127.0.0.1";
        openFirewall = false;

        options = {
          calibreLibrary = cfg.libraryDir;
          enableBookUploading = false;
          enableBookConversion = true;

          reverseProxyAuth = {
            inherit (config.infra.authelia) enable;
            header = "Remote-User";
          };
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig = ''
          @calibre path /${cfg.matcher} /${cfg.matcher}/*
          handle @calibre {
            ${lib.optionalString config.infra.authelia.enable ''
              forward_auth :${builtins.toString config.infra.authelia.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }
            ''}

            # This is needed when running on a subpath, as opposed to a subdomain.
            request_header X-Script-Name "/${cfg.matcher}"
            reverse_proxy :${builtins.toString config.services.calibre-web.listen.port}
          }
        '';
      };
    };
  };
}
