{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.infra.healthchecks;
in
{
  options.infra.healthchecks = {
    enable = lib.mkEnableOption "healthchecks";
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.keepalive = {
        description = "Keepalive signal";

        serviceConfig = {
          EnvironmentFile = config.age.secrets."healthchecks/env".path;
          Type = "oneshot";

          DynamicUser = true;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          PrivateTmp = true;
          ProtectHome = true;
          ProtectClock = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          RestrictSUIDGUID = true;
          UMask = "0077";
          LockPersonality = true;
          RestrictRealtime = true;
          MemoryDenyWriteExecute = true;

          ExecStart =
            let
              script = pkgs.writeShellApplication {
                name = "keepalive";
                runtimeInputs = [ pkgs.curl ];

                text = ''
                  curl --fail --silent --show-error --max-time 10 --retry 5 --output /dev/null "$HC_URL"
                '';
              };
            in
            lib.getExe script;
        };
      };

      timers.keepalive = {
        description = "Keepalive timer";
        wantedBy = [ "timers.target" ];
        partOf = [ "keepalive.service" ];

        timerConfig = {
          OnBootSec = "10m";
          OnUnitActiveSec = "10m";
        };
      };
    };
  };
}
