{ config, lib, ... }:

let
  cfg = config.infra.calibre-web;
in
{
  options.infra.calibre-web = {
    enable = lib.mkEnableOption "calibre-web";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain calibre-web is available on";
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
            inherit (config.infra.authentication) enable;
            header = "Remote-User";
          };
        };
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain}.extraConfig =
          if config.infra.authentication.enable then
            ''
              forward_auth :${builtins.toString config.infra.authentication.port} {
                uri /api/authz/forward-auth
                copy_headers Remote-User
              }

              reverse_proxy :${builtins.toString config.services.calibre-web.listen.port}
            ''
          else
            ''
              reverse_proxy :${builtins.toString config.services.calibre-web.listen.port}
            '';
      };
    };
  };
}
