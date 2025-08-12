{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.tailscale;
in
{
  options.infra.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale-api-key.path;
      permitCertUid = "caddy";
    };
  };
}
