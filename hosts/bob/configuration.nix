{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "exocomet-hippocampus.ts.net";
  hostName = "bob";
  hostDomain = "${hostName}.${domain}";
  mediaDir = "/mnt/media";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos-server/authelia.nix
    ../../modules/nixos-server/calibre-web.nix
    ../../modules/nixos-server/homepage.nix
    ../../modules/nixos-server/jellyfin.nix
    ../../modules/nixos-server/navidrome.nix
    ../../modules/nixos-server/tailscale.nix
    ../../modules/nixos-server/tandoor.nix
  ];

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
      };
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    system.stateVersion = "25.05";
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;

    fileSystems.${mediaDir} = {
      device = "//10.0.0.10/Media";
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
        in
        [
          "${builtins.concatStringsSep "," automount},credentials=${config.age.secrets.nas-smb-credentials.path}"
        ];
    };

    age.secrets = {
      tomas-password.file = ../../secrets/bob/users/tomas.age;
      root-password.file = ../../secrets/bob/users/root.age;
      tailscale-api-key.file = ../../secrets/bob/tailscale-api-key.age;
      homepage-env.file = ../../secrets/bob/homepage-env.age;
      nas-smb-credentials.file = ../../secrets/bob/nas-smb-credentials.age;

      # Resource: https://www.authelia.com/configuration/methods/secrets/#environment-variables
      authelia-postgres-password = {
        file = ../../secrets/bob/authelia/postgres-password.age;
        mode = "0640";
        owner = "root";
        group = "authelia-main";
      };
      authelia-jwt-secret = {
        file = ../../secrets/bob/authelia/jwt-secret.age;
        mode = "0640";
        owner = "root";
        group = "authelia-main";
      };
      authelia-session-secret = {
        file = ../../secrets/bob/authelia/session-secret.age;
        mode = "0640";
        owner = "root";
        group = "authelia-main";
      };
      authelia-storage-encryption-key = {
        file = ../../secrets/bob/authelia/storage-encryption-key.age;
        mode = "0640";
        owner = "root";
        group = "authelia-main";
      };
      authelia-users = {
        file = ../../secrets/bob/authelia/users.age;
        mode = "0640";
        owner = "root";
        group = "authelia-main";
      };

      tandoor-secret-key = {
        file = ../../secrets/bob/tandoor-secret-key.age;
        mode = "0640";
        owner = "root";
        group = "tandoor_recipes";
      };
    };

    users = {
      mutableUsers = false;

      users = {
        root.hashedPasswordFile = config.age.secrets.root-password.path;

        tomas = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          hashedPasswordFile = config.age.secrets.tomas-password.path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9wbboIeutdnZFbYT5zwJNBf4fJy9njfEMwxOnJKh4z blacklodge2bob"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6BGS5Ty3Oaozhow1qwTsOitN6Ksje4GEzheMzXoijW gordon2bob"
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
        curl
        jq
        ldns
        ripgrep
        rsync
        tree
      ];
    };

    networking = {
      inherit hostName;

      firewall = {
        enable = true;

        allowedTCPPorts = lib.mkIf config.services.caddy.enable [
          80
          443
        ];
      };

      nftables.enable = true;
    };

    services = {
      fwupd.enable = true;

      openssh = {
        enable = true;

        settings = {
          X11Forwarding = false;
          GatewayPorts = "no";
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
    };

    infra = {
      tailscale.enable = true;

      authelia = {
        enable = true;
        domain = hostDomain;
      };

      homepage = {
        enable = true;
        domain = hostDomain;
      };

      calibre-web = {
        enable = true;
        domain = hostDomain;
      };

      jellyfin = {
        enable = true;
        domain = hostDomain;
      };

      navidrome = {
        enable = true;
        domain = hostDomain;
        musicDir = "${mediaDir}/music";
      };

      tandoor = {
        enable = true;
        domain = hostDomain;
      };
    };
  };
}
