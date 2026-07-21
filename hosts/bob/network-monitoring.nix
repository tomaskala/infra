{ config, ... }:
 
let
  alloyListenPort = 1514;
in
{
  networking.firewall.extraInputRules = ''
    ip saddr { 10.0.50.1 } udp dport ${builtins.toString alloyListenPort} accept
  '';

  environment.etc."alloy/config.alloy".text = ''
    loki.source.syslog "mikrotik" {
      listener {
        address       = "0.0.0.0:${builtins.toString alloyListenPort}"
        protocol      = "udp"
        syslog_format = "rfc3164"
        labels        = { job = "mikrotik" }
      }
      forward_to = [loki.relabel.mikrotik.receiver]
    }

    loki.relabel "mikrotik" {
      forward_to = [loki.write.local.receiver]
      rule {
        source_labels = ["__syslog_message_hostname"]
        target_label  = "host"
      }
      rule {
        source_labels = ["__syslog_message_severity"]
        target_label  = "severity"
      }
    }

    loki.write "local" {
      endpoint {
        url = "http://127.0.0.1:${builtins.toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"
      }
    }
  '';
}
