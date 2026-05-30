{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/programs.nix
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

    system.stateVersion = "26.05";
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;

    age = {
      identityPaths = [ "/home/tomas/.ssh/id_ed25519_agenix" ];

      secrets = {
        "users/tomas-password".file = ../../secrets/cooper/users/tomas-password.age;
        "users/root-password".file = ../../secrets/cooper/users/root-password.age;
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
          extraGroups = [
            "audio"
            "networkmanager"
            "users"
            "video"
            "wheel"
            "wireshark"
          ];
        };
      };
    };

    programs = {
      firefox.enable = true;
      thunderbird.enable = true;

      wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };
    };

    environment.systemPackages = with pkgs; [
      # System utilities
      sbctl

      # General development
      gnumake
      shellcheck

      # Go development
      go
      golangci-lint
      gotools

      # Lua development
      lua

      # Python development
      python3
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
