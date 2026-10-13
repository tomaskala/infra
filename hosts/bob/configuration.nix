{
  config,
  pkgs,
  inputs,
  ...
}:

let
  hostName = "bob";
  hostDomain = "${hostName}.the-great-northern.com";
  mediaDir = "/mnt/media";
in
{
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/programs.nix
    ../../modules/nixos-server/audiobookshelf.nix
    ../../modules/nixos-server/authelia.nix
    ../../modules/nixos-server/forgejo.nix
    ../../modules/nixos-server/healthchecks.nix
    ../../modules/nixos-server/homepage.nix
    ../../modules/nixos-server/jellyfin.nix
    ../../modules/nixos-server/monitoring.nix
    ../../modules/nixos-server/navidrome.nix
    ../../modules/nixos-server/paperless.nix
    ../../modules/nixos-server/readeck.nix
    ../../modules/nixos-server/tailscale.nix
  ];

  config = {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    system.stateVersion = "26.05";
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;

    fileSystems.${mediaDir} = {
      device = "//10.0.50.11/Media";
      fsType = "cifs";
      options =
        let
          automount = [
            "x-systemd.automount" # Automatically mount upon first access.
            "noauto" # Do not mount when the machine starts.
            "x-systemd.idle-timeout=3600" # Automatically disconnect after being idle.
            "x-systemd.device-timeout=5s" # Wait for this long for the device to show up.
            "x-systemd.mount-timeout=5s" # Wait for this long for the mount command to finish.
            "ro" # Mount as a read-only filesystem.
          ];

          security = [
            "credentials=${config.age.secrets."nas/smb-credentials".path}"
            "seal" # Use encryption (requires at least SMB 3.0).
            "nosuid" # Ignore setuid/setgid bits and file capabilities from the share.
            "nodev" # Ignore device nodes on the share, so crafted files can't access hardware.
            "noexec" # Block executing files directly from the share.
            "vers=3.1.1" # Require SMBv3.1.1.
          ];
        in
        [
          (builtins.concatStringsSep "," (automount ++ security))
        ];
    };

    age = {
      identityPaths = [ "/etc/agenix/agenix.key" ];

      secrets =
        let
          ownedBy = owner: file: {
            inherit owner file;
            mode = "0400";
          };
        in
        {
          "users/tomas-password".file = ../../secrets/bob/users/tomas-password.age;
          "users/root-password".file = ../../secrets/bob/users/root-password.age;
          "acme/env".file = ../../secrets/bob/acme/env.age;
          "nas/smb-credentials".file = ../../secrets/bob/nas/smb-credentials.age;
          "readeck/env".file = ../../secrets/bob/readeck/env.age;
          "healthchecks/env".file = ../../secrets/bob/healthchecks/env.age;
          "prometheus/snmp-env".file = ../../secrets/bob/prometheus/snmp-env.age;
          "paperless/admin-password".file = ../../secrets/bob/paperless/admin-password.age;
          "paperless/env".file = ../../secrets/bob/paperless/env.age;
          "navidrome/env".file = ../../secrets/bob/navidrome/env.age;

          "tailscale/api-key" = ownedBy "tailscaled" ../../secrets/bob/tailscale/api-key.age;

          # Source: <https://www.authelia.com/configuration/methods/secrets/#environment-variables>.
          "authelia/postgres-password" =
            ownedBy "authelia-main" ../../secrets/bob/authelia/postgres-password.age;
          "authelia/jwt-secret" = ownedBy "authelia-main" ../../secrets/bob/authelia/jwt-secret.age;
          "authelia/session-secret" = ownedBy "authelia-main" ../../secrets/bob/authelia/session-secret.age;
          "authelia/storage-encryption-key" =
            ownedBy "authelia-main" ../../secrets/bob/authelia/storage-encryption-key.age;
          "authelia/users" = ownedBy "authelia-main" ../../secrets/bob/authelia/users.age;
          "authelia/oidc-hmac-secret" =
            ownedBy "authelia-main" ../../secrets/bob/authelia/oidc-hmac-secret.age;
          "authelia/oidc-issuer-private-key" =
            ownedBy "authelia-main" ../../secrets/bob/authelia/oidc-issuer-private-key.age;

          "grafana/admin-password" = ownedBy "grafana" ../../secrets/bob/grafana/admin-password.age;
          "grafana/secret-key" = ownedBy "grafana" ../../secrets/bob/grafana/secret-key.age;
          "grafana/authelia-password" = ownedBy "grafana" ../../secrets/bob/grafana/authelia-password.age;
        };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.tomas = ./tomas.nix;
    };

    users = {
      mutableUsers = false;

      users = {
        root.hashedPasswordFile = config.age.secrets."users/root-password".path;

        tomas = {
          isNormalUser = true;
          hashedPasswordFile = config.age.secrets."users/tomas-password".path;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBviQmhfUXTCnR5q/OFMfsbRNoYrbODXGo+ddvFZsp5K tomas@blacklodge"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6BGS5Ty3Oaozhow1qwTsOitN6Ksje4GEzheMzXoijW tomas@gordon"
          ];
        };
      };
    };

    time.timeZone = "Europe/Prague";
    i18n.defaultLocale = "en_US.UTF-8";

    programs = {
      git.enable = true;
      htop.enable = true;

      tmux = {
        enable = true;
        baseIndex = 1;
        clock24 = true;

        extraConfigBeforePlugins = ''
          # ============================================= #
          # Start with defaults from the Sensible plugin  #
          # --------------------------------------------- #
          run-shell ${pkgs.tmuxPlugins.sensible.rtp}
          # ============================================= #
        '';
      };

      neovim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;
        withNodeJs = false;
        withPython3 = false;
        withRuby = false;
      };
    };

    environment = {
      enableAllTerminfo = true;

      systemPackages = with pkgs; [
        cifs-utils # Needed for mounting NAS using SMB.
      ];
    };

    networking = {
      inherit hostName;
      hostId = "527acb68";

      firewall.enable = true;
      nftables.enable = true;
    };

    security = {
      sudo = {
        enable = true;
        execWheelOnly = true;
      };

      acme = {
        acceptTerms = true;
        defaults.email = "public+acme@tomaskala.com";

        certs.${hostDomain} = {
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets."acme/env".path;
          extraDomainNames = [ "*.${hostDomain}" ];
        };
      };
    };

    services = {
      caddy.openFirewall = true;

      chrony = {
        enable = true;
        enableNTS = true;

        servers = [
          "time.cloudflare.com"
          "1.ntp.ubuntu.com"
          "2.ntp.ubuntu.com"
          "3.ntp.ubuntu.com"
          "4.ntp.ubuntu.com"
        ];
      };

      fwupd.enable = true;

      openssh = {
        enable = true;
        openFirewall = true;

        settings = {
          X11Forwarding = false;
          GatewayPorts = "no";
          PermitRootLogin = "no";
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
        };
      };

      prometheus = {
        exporters = {
          node = {
            enable = true;
            listenAddress = "127.0.0.1";
            enabledCollectors = [ "hwmon" ];
          };

          snmp = {
            enable = true;
            listenAddress = "127.0.0.1";
            configurationPath = ./snmp.yml;
            environmentFile = config.age.secrets."prometheus/snmp-env".path;
          };

          smartctl = {
            enable = true;
            listenAddress = "127.0.0.1";
          };
        };

        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${builtins.toString config.services.prometheus.exporters.node.port}"
                ];
              }
            ];
          }
          {
            job_name = "snmp";
            static_configs = [
              {
                targets = [ "10.0.50.11" ];
              }
            ];
            metrics_path = "/snmp";
            params = {
              auth = [ "synology" ];
              module = [ "synology" ];
            };
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${builtins.toString config.services.prometheus.exporters.snmp.port}";
              }
            ];
          }
          {
            job_name = "smartctl";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${builtins.toString config.services.prometheus.exporters.smartctl.port}"
                ];
              }
            ];
          }
        ];
      };

      thermald.enable = true;
    };

    infra = {
      audiobookshelf = {
        enable = true;
        inherit hostDomain;
        subdomain = "audiobookshelf";
        booksDir = "${mediaDir}/ebooks";
      };

      authelia = {
        enable = true;
        inherit hostDomain;
        subdomain = "auth";
      };

      forgejo = {
        enable = true;
        inherit hostDomain;
        subdomain = "forgejo";
      };

      healthchecks.enable = true;

      homepage = {
        enable = true;
        inherit hostDomain;
      };

      jellyfin = {
        enable = true;
        inherit hostDomain;
        subdomain = "jellyfin";
      };

      monitoring = {
        enable = true;
        inherit hostDomain;
        subdomain = "monitoring";
      };

      navidrome = {
        enable = true;
        inherit hostDomain;
        subdomain = "navidrome";

        musicDir = {
          source = "${mediaDir}/music/";
          destination = "/media/music/";
        };
      };

      paperless = {
        enable = true;
        inherit hostDomain;
        subdomain = "paperless";
      };

      readeck = {
        enable = true;
        inherit hostDomain;
        subdomain = "readeck";
      };

      tailscale.enable = true;
    };
  };
}
