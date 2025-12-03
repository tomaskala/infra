{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos-desktop/audio.nix
    ../../modules/nixos-desktop/gnome.nix
    ../../modules/nixos-desktop/firewall.nix
    ../../modules/nixos-desktop/gaming.nix
    ../../modules/nixos-desktop/locale.nix
    ../../modules/nixos-desktop/network.nix
    ../../modules/nixos-desktop/phone.nix
    ../../modules/nixos-desktop/tailscale.nix
    ../../modules/nixos-desktop/virtualisation.nix
  ];

  config = {
    hardware = {
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;
    };

    boot = {
      plymouth.enable = true;

      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
      };

      initrd.systemd.enable = true;
      loader.systemd-boot.enable = lib.mkForce false;

      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
    };

    systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

    nix.settings.trusted-users = [
      "root"
      "tomas"
    ];

    system.stateVersion = "24.05";

    nixpkgs.config.allowUnfree = true;

    age = {
      identityPaths = [ "/home/tomas/.ssh/id_ed25519_agenix" ];

      secrets = {
        users-tomas-password.file = ../../secrets/cooper/users/tomas.age;
        users-root-password.file = ../../secrets/cooper/users/root.age;
      };
    };

    users = {
      mutableUsers = false;

      users = {
        root.hashedPasswordFile = config.age.secrets.users-root-password.path;

        tomas = {
          isNormalUser = true;
          extraGroups = [
            "audio"
            "networkmanager"
            "users"
            "video"
            "wheel"
            "wireshark"
          ];
          hashedPasswordFile = config.age.secrets.users-tomas-password.path;
          shell = pkgs.zsh;
        };
      };
    };

    catppuccin = {
      enable = true;
      flavor = "macchiato";
      accent = "mauve";
    };

    programs = {
      firefox.enable = true;
      thunderbird.enable = true;
      zsh.enable = true;

      wireshark = {
        enable = true;
        package = pkgs.wireshark-qt;
      };
    };

    environment.systemPackages = with pkgs; [
      # System utilities
      man-pages
      man-pages-posix
      rsync
      sbctl
      tree

      # Networking
      curl
      ldns
      nmap
      openssl
      tcpdump
      whois

      # Development
      gnumake
      go
      gotools
      lua
      python3
      shellcheck
      uv

      # Media
      hugo
      libreoffice-still

      # Communication
      discord
      telegram-desktop
    ];

    networking.hostName = "cooper";

    security = {
      polkit.enable = true;

      sudo = {
        enable = true;
        execWheelOnly = true;
      };
    };

    services = {
      ntp.enable = false;
      timesyncd.enable = true;
      fstrim.enable = true;
      fwupd.enable = true;
    };
  };
}
