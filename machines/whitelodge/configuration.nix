{ config, pkgs, secrets, util, ... }:

let
  intranetCfg = config.infra.intranet;
  acmeEmail = "public+acme@tomaskala.com";
in {
  imports = [
    ./home.nix
    ./modules/firewall.nix
    ./modules/mealie.nix
    ./modules/miniflux.nix
    ./modules/monitoring-hub.nix
    ./modules/radicale.nix
    ./modules/website.nix
    ./modules/wireguard.nix
    ../../intranet
    ../../modules/blocky.nix
    ../../modules/openssh.nix
  ];

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        # The system is running on ZFS, so we don't need Nix generations.
        options = "--delete-old";
      };

      settings = {
        # Optimise the store after each build (as opposed to nix.optimise.*
        # which sets up a systemd timer to optimise the store periodically).
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
      };
    };

    system.autoUpgrade = {
      enable = true;
      operation = "switch";
      flake = "github:tomaskala/infra";

      # Run after the automatic flake.lock update configured in Github Actions.
      dates = "Sun *-*-* 03:00:00";

      # The system runs in a container, sharing the Linux kernel with other
      # containers. As such, no kernel upgrades can happen during a system
      # upgrade, and no reboot is necessary. When enabled, this broke the
      # nixos-upgrade service because it attempted to read non-existent
      # files under /run/booted-system.
      allowReboot = false;
    };

    age.secrets = {
      users-tomas-password.file =
        "${secrets}/secrets/users/whitelodge/tomas.age";
      users-root-password.file = "${secrets}/secrets/users/whitelodge/root.age";

      wg-whitelodge-internal-pk = {
        file = "${secrets}/secrets/wg-pk/whitelodge/internal.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-whitelodge-isolated-pk = {
        file = "${secrets}/secrets/wg-pk/whitelodge/isolated.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-whitelodge-passthru-pk = {
        file = "${secrets}/secrets/wg-pk/whitelodge/passthru.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-bob2whitelodge = {
        file = "${secrets}/secrets/wg-psk/bob2whitelodge.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-cooper2whitelodge = {
        file = "${secrets}/secrets/wg-psk/cooper2whitelodge.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-tomas-phone2whitelodge = {
        file = "${secrets}/secrets/wg-psk/tomas-phone2whitelodge.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-blacklodge2whitelodge = {
        file = "${secrets}/secrets/wg-psk/blacklodge2whitelodge.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };

      wg-audrey2whitelodge = {
        file = "${secrets}/secrets/wg-psk/audrey2whitelodge.age";
        mode = "0640";
        owner = "root";
        group = "systemd-network";
      };
    };

    users = {
      mutableUsers = false;

      users = {
        root.hashedPasswordFile = config.age.secrets.users-root-password.path;

        tomas = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          hashedPasswordFile = config.age.secrets.users-tomas-password.path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvN19BcNTeaVAF291lBG0z9ROD6J91XAMyy+0VP6CdL cooper2whitelodge"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRpAi2U+EW2dhKv/tu2DVJPNZnrqgQway2CSAs38tFl blacklodge2whitelodge"
          ];
        };

        git = {
          isSystemUser = true;
          createHome = true;
          home = "/home/git";
          shell = "${pkgs.git}/bin/git-shell";
          group = "git";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbhtSz3s/zgTVWg7d37J9qeKk+u4H+jJhwvj/QXjaIW cooper2whitelodge-git"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIApzsZJs9oocJnP2JnIsSZFmmyWdUm/2IgRHcJgCqFc1 tomas-phone2whitelodge-git"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3iFrxprV/hToSeHEIo2abt/IcK/M86iqF4mV6S81Rf blacklodge2whitelodge-git"
          ];
        };
      };

      groups.git = { };
    };

    time.timeZone = "Etc/UTC";

    programs = {
      git = {
        enable = true;
        config.init.defaultBranch = "master";
      };

      htop.enable = true;

      tmux = {
        enable = true;
        escapeTime = 1;
        clock24 = true;
        baseIndex = 1;
      };

      vim.defaultEditor = true;
    };

    environment = {
      noXlibs = true;
      systemPackages = with pkgs; [ curl ldns rsync tree wireguard-tools ];
    };

    networking = {
      hostName = "whitelodge";
      useDHCP = false;
    };

    services = {
      ntp.enable = false;
      timesyncd.enable = true;

      openssh = {
        enable = true;
        listenAddresses = [
          {
            addr = util.ipAddress
              intranetCfg.devices.whitelodge.wireguard.internal.ipv4;
            port = 22;
          }
          {
            addr = util.ipAddress
              intranetCfg.devices.whitelodge.wireguard.internal.ipv6;
            port = 22;
          }
        ];
      };

      prometheus.exporters = {
        node = {
          enable = true;
          openFirewall = false;
          listenAddress = "127.0.0.1";
          port = 9100;
          enabledCollectors = [ "processes" "systemd" ];
        };
      };
    };

    infra = {
      blocky = {
        enable = true;

        listenAddresses = [
          # Allow the server itself to use the resolver.
          {
            addr = "127.0.0.1";
            port = 53;
          }
          {
            addr = "[::1]";
            port = 53;
          }
          # Allow internal peers to use the resolver. This is to allow
          # resolving internal domain names as well as to use it for
          # domain filtering when accessing the public internet.
          {
            addr = util.ipAddress
              intranetCfg.devices.whitelodge.wireguard.internal.ipv4;
            port = 53;
          }
          {
            addr = "[${
                util.ipAddress
                intranetCfg.devices.whitelodge.wireguard.internal.ipv6
              }]";
            port = 53;
          }
          # Allow isolated peers to use the resolver. This is to allow
          # resolving internal domain names.
          {
            addr = util.ipAddress
              intranetCfg.devices.whitelodge.wireguard.isolated.ipv4;
            port = 53;
          }
          {
            addr = "[${
                util.ipAddress
                intranetCfg.devices.whitelodge.wireguard.isolated.ipv6
              }]";
            port = 53;
          }
          # Allow passthru peers to use the resolver. This is to allow
          # them to use a trusted resolver. Although it will resolve
          # internal domain names, the passthru peers do not have access
          # to those services.
          {
            addr = util.ipAddress
              intranetCfg.devices.whitelodge.wireguard.passthru.ipv4;
            port = 53;
          }
          {
            addr = "[${
                util.ipAddress
                intranetCfg.devices.whitelodge.wireguard.passthru.ipv6
              }]";
            port = 53;
          }
        ];

        metrics = {
          addr = "127.0.0.1";
          port = 4000;
        };
      };

      firewall.enable = true;

      mealie = {
        enable = true;
        port = 9000;
        inherit acmeEmail;
      };

      miniflux = {
        enable = true;
        port = 7070;
        inherit acmeEmail;
      };

      monitoring-hub = {
        enable = true;
        grafanaPort = 3000;
        prometheusPort = 9090;
        inherit acmeEmail;

        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "127.0.0.1:9100" ];
                labels = { peer = "whitelodge"; };
              }
              {
                targets = [
                  "${
                    util.ipAddress
                    intranetCfg.devices.bob.wireguard.isolated.ipv4
                  }:9100"
                ];
                labels = { peer = "bob"; };
              }
            ];
          }
          {
            job_name = "blocky";
            static_configs = [
              {
                targets = [ "127.0.0.1:4000" ];
                labels = { peer = "whitelodge"; };
              }
              {
                targets = [
                  "${
                    util.ipAddress
                    intranetCfg.devices.bob.wireguard.isolated.ipv4
                  }:4000"
                ];
                labels = { peer = "bob"; };
              }
            ];
          }
        ];
      };

      radicale = {
        enable = true;
        port = 5232;
        inherit acmeEmail;
      };

      website = {
        enable = true;
        domain = "tomaskala.com";
        webroot = "/var/www/tomaskala.com";
        inherit acmeEmail;
      };

      wireguard = {
        enable = true;
        enableInternal = true;
        enableIsolated = true;
        enablePassthru = true;
      };
    };
  };
}
