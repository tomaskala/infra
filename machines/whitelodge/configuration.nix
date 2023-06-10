{ config, pkgs, ... }:

# TODO: Pull secrets from a private repository.

let
  publicDomain = "tomaskala.com";
  publicDomainWebroot = "/var/www/${publicDomain}";
  acmeEmail = "public+acme@${publicDomain}";

  rssDomain = "rss.home.arpa";
  rssListenPort = 7070;

  wanInterface = "venet0";

  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
  intranetCfg = config.networking.intranet;
in {
  imports = [
    ./overlay-network.nix
    ./secrets-management.nix
    ../intranet.nix
    ../../services/openssh.nix
    ../../services/unbound-blocker.nix
    ../../services/unbound.nix
    ../../services/yarr.nix
  ];

  config = {
    system = {
      stateVersion = "23.05";

      autoUpgrade = {
        enable = true;
        dates = "05:00";
        allowReboot = true;
        flake = "github:tomaskala/infra";
      };
    };

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        # The system is running on ZFS, so we don't need Nix generations.
        options = "--delete-old";
      };

      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
      };
    };

    users.users.tomas = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      passwordFile = config.age.secrets.users-tomas-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRpAi2U+EW2dhKv/tu2DVJPNZnrqgQway2CSAs38tFl home2whitelodge"
      ];
    };

    programs.git.config.init.defaultBranch = "master";
    users.groups.git = { };
    users.users.git = {
      isSystemUser = true;
      createHome = true;
      home = "/home/git";
      shell = "${pkgs.git}/bin/git-shell";
      group = "git";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIApzsZJs9oocJnP2JnIsSZFmmyWdUm/2IgRHcJgCqFc1 phone2whitelodge-git"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3iFrxprV/hToSeHEIo2abt/IcK/M86iqF4mV6S81Rf home2whitelodge-git"
      ];
    };

    time.timeZone = "Europe/Prague";
    services.ntp.enable = false;
    services.timesyncd.enable = true;

    programs.vim.defaultEditor = true;
    environment.systemPackages = with pkgs; [
      curl
      git
      ldns
      rsync
      tmux
      wireguard-tools
    ];

    networking.hostName = "whitelodge";
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      checkRuleset = true;
      ruleset = import ./nftables-ruleset.nix { inherit config wanInterface; };
    };

    systemd.network = {
      enable = true;

      netdevs."90-${intranetCfg.server.interface}" = {
        netdevConfig = {
          Name = intranetCfg.server.interface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-server-pk.path;
          ListenPort = intranetCfg.server.port;
        };

        wireguardPeers = [
          {
            wireguardPeerConfig = {
              # tomas-phone
              PublicKey = "DTJ3VeQGDehQBkYiteIpxtatvgqy2Ux/KjQEmXaEoEQ=";
              PresharedKeyFile = config.age.secrets.wg-tomas-phone-psk.path;
              AllowedIPs = [ "10.100.100.2/32" "fd25:6f6:a9f:1100::2/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # martin-windows
              PublicKey = "JoxRQuYsNZqg/e/DHIVnAsDsA86PjyDlIWPIViMrPUQ=";
              PresharedKeyFile = config.age.secrets.wg-martin-windows-psk.path;
              AllowedIPs = [ "10.100.104.1/32" "fd25:6f6:a9f:1200::1/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # tomas-home
              PublicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
              PresharedKeyFile = config.age.secrets.wg-tomas-home-psk.path;
              AllowedIPs = [ "10.100.100.3/32" "fd25:6f6:a9f:1100::3/128" ];
            };
          }
        ];
      };

      networks."90-${intranetCfg.server.interface}" = {
        matchConfig.Name = intranetCfg.server.interface;

        address = [
          "${intranetCfg.server.ipv4}/${
            builtins.toString intranetCfg.ipv4.mask
          }"
          "${intranetCfg.server.ipv6}/${
            builtins.toString intranetCfg.ipv6.mask
          }"
        ];
      };
    };

    networking.overlay-network.enable = true;

    services.openssh = {
      enable = true;

      listenAddresses = [
        {
          addr = intranetCfg.server.ipv4;
          port = 22;
        }
        {
          addr = intranetCfg.server.ipv6;
          port = 22;
        }
      ];
    };

    services.yarr = {
      enable = true;
      listenPort = rssListenPort;
    };

    services.caddy = {
      enable = true;
      email = acmeEmail;

      virtualHosts.${publicDomain} = {
        extraConfig = ''
          root * ${publicDomainWebroot}
          encode gzip
          file_server
        '';
      };

      # Explicitly specify HTTP to disable automatic TLS certificate creation,
      # since this is an internal domain only accessible from the VPN anyway.
      virtualHosts."http://${rssDomain}" = {
        listenAddresses = [ intranetCfg.server.ipv4 intranetCfg.server.ipv6 ];

        extraConfig = ''
          reverse_proxy :${builtins.toString rssListenPort}

          @blocked not remote_ip ${maskSubnet intranetCfg.ipv4} ${
            maskSubnet intranetCfg.ipv6
          }
          respond @blocked "Forbidden" 403
        '';
      };
    };

    services.unbound = {
      enable = true;

      settings.server = {
        interface =
          [ "127.0.0.1" "::1" intranetCfg.server.ipv4 intranetCfg.server.ipv6 ];
        port = 53;
        access-control = [
          "127.0.0.1/8 allow"
          "::1/128 allow"
          "${maskSubnet intranetCfg.ipv4} allow"
          "${maskSubnet intranetCfg.ipv6} allow"
        ];
      };

      localDomains = [
        {
          domain = publicDomain;
          inherit (intranetCfg.server) ipv4 ipv6;
        }
        {
          domain = rssDomain;
          inherit (intranetCfg.server) ipv4 ipv6;
        }
      ];
    };

    services.unbound-blocker.enable = true;
  };
}