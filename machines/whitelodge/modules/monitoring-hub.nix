{ config, lib, options, util, ... }:

let
  cfg = config.services.monitoring-hub;
  intranetCfg = config.networking.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;
  allowedIPs = builtins.map util.ipSubnet [
    intranetCfg.vpn.internal.ipv4
    intranetCfg.vpn.internal.ipv6
  ];
  dbName = "grafana";
in {
  options.services.monitoring-hub = {
    enable = lib.mkEnableOption "monitoring-hub";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain hosting Grafana";
      default = "monitoring.whitelodge.tomaskala.com";
      readOnly = true;
    };

    grafanaPort = lib.mkOption {
      type = lib.types.port;
      description = "Port that Grafana listens on";
      example = 3000;
    };

    prometheusPort = lib.mkOption {
      type = lib.types.port;
      description = "Port that Prometheus listens on";
      example = 9090;
    };

    scrapeConfigs = lib.mkOption {
      inherit (options.services.prometheus.scrapeConfigs) type;
      description = "A list of scrape configurations";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "ACME account email address";
      example = "acme@example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      certs.${cfg.domain} = {
        dnsProvider = "cloudflare";
        email = cfg.acmeEmail;
        environmentFile =
          config.age.secrets.cloudflare-dns-challenge-api-tokens.path;
      };
    };

    services = {
      grafana = {
        enable = true;

        provision = {
          enable = true;

          datasources.settings.datasources = [{
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${builtins.toString cfg.prometheusPort}";
          }];

          dashboards.settings.providers = [{
            name = "Grafana dashboards";
            # It's useless to check the dashboard directory for updates because
            # it lives on a readonly file system, but grafana doesn't allow to
            # disable the checking completely. Even setting this value to zero
            # doesn't help, because in that case, it gets silently converted
            # to 10 anyway:
            # https://github.com/grafana/grafana/blob/bc2813ef0661eb0fd317a7ed2dff4db056cbe7e6/pkg/services/provisioning/dashboards/config_reader.go#L107-L109
            # Setting to a large value instead to not check too often.
            updateIntervalSeconds = 60 * 60 * 24;
            options.path = "${../grafana-dashboards}";
          }];
        };

        settings = {
          server = {
            inherit (cfg) domain;
            http_addr = "127.0.0.1";
            http_port = cfg.grafanaPort;
            enable_gzip = true;
          };

          analytics = {
            reporting_enabled = false;
            feedback_links_enabled = false;
            check_for_updates = false;
            check_for_plugin_updates = false;
          };

          database = {
            type = "postgres";
            host = "/run/postgresql";
            name = dbName;
            user = dbName;
            passwordFile = config.age.secrets.postgresql-grafana-password.path;
          };

          security = {
            disable_gravatar = true;
            admin_password =
              "$__file{${config.age.secrets.grafana-admin-password.path}}";
          };

          "auth.anonymous" = {
            enabled = true;
            org_name = "Main Org.";
            org_role = "Viewer";
          };
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = [ dbName ];
        ensureUsers = [{
          name = dbName;
          ensureDBOwnership = true;
        }];
      };

      prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = cfg.prometheusPort;
        inherit (cfg) scrapeConfigs;
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          listenAddresses = [
            (util.ipAddress deviceCfg.wireguard.internal.ipv4)
            "[${util.ipAddress deviceCfg.wireguard.internal.ipv6}]"
          ];

          useACMEHost = cfg.domain;

          extraConfig = ''
            encode {
              zstd
              gzip 5
            }

            @internal {
              remote_ip ${builtins.toString allowedIPs}
            }

            handle @internal {
              reverse_proxy :${
                builtins.toString
                config.services.grafana.settings.server.http_port
              }
            }

            respond "Access denied" 403 {
              close
            }
          '';
        };
      };
    };

    networking.intranet.vpn.internal.services.monitoring-hub = {
      url = cfg.domain;
      inherit (deviceCfg.wireguard.internal) ipv4 ipv6;
    };
  };
}
