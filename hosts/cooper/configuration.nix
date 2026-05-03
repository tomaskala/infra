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
    ../../modules/nixos-desktop/firewall.nix
    ../../modules/nixos-desktop/gnome.nix
    ../../modules/nixos-desktop/locale.nix
    ../../modules/nixos-desktop/network.nix
    ../../modules/nixos-desktop/phone.nix
    ../../modules/nixos-desktop/printing.nix
    ../../modules/nixos-desktop/tailscale.nix
  ];

  config = {
    nix.settings.trusted-users = [
      "root"
      "tomas"
    ];

    boot = {
      initrd.systemd.enable = true;
      loader.systemd-boot.enable = lib.mkForce false;

      lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        autoGenerateKeys.enable = true;

        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };
      };
    };

    system.stateVersion = "24.05";
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;

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
      fstrim.enable = true;
      fwupd.enable = true;
    };
  };
}
