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
            "credentials=${config.sops.secrets."nas/smb-credentials".path}"
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

    sops = {
      defaultSopsFile = ./secrets.yaml;
      age.keyFile = "/etc/sops/sops-nix.key";

      secrets = {
        "users/tomas".neededForUsers = true;
        "users/root".neededForUsers = true;

        "acme/env" = { };
        "nas/smb-credentials" = { };
        "prometheus/snmp-env" = { };
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
        root.hashedPasswordFile = config.sops.secrets."users/root".path;

        tomas = {
          isNormalUser = true;
          hashedPasswordFile = config.sops.secrets."users/tomas".path;
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
          environmentFile = config.sops.secrets."acme/env".path;
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
            environmentFile = config.sops.secrets."prometheus/snmp-env".path;
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
