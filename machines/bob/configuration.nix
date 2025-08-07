{
  config,
  pkgs,
  secrets,
  ...
}:

let
  domain = "bob.exocomet-hippocampus.ts.net";
  mediaDir = "/mnt/media";
in
{
  imports = [
    ./modules/authentication.nix
    ./modules/calibre-web.nix
    ./modules/homepage.nix
    ./modules/navidrome.nix
    ./modules/tailscale.nix
  ];

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
      };
    };

    system.stateVersion = "25.05";
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;

    fileSystems.${mediaDir} = {
      device = "10.0.0.10:/volume1/Media";
      fsType = "nfs";
      options = [
        "nfsvers=4.1" # Use NFSv4.1 (the highest my NAS supports).
        "x-systemd.automount" # Automatically mount upon first access.
        "noauto" # Do not mount when the machine starts.
        "x-systemd.idle-timeout=3600" # Automatically disconnect after being idle.
        "ro" # Mount as a read-only filesystem.
      ];
    };

    age.secrets = {
      tomas-password.file = "${secrets}/secrets/bob/users/tomas.age";
      root-password.file = "${secrets}/secrets/bob/users/root.age";
      tailscale-api-key.file = "${secrets}/secrets/bob/tailscale-api-key.age";
      homepage-env.file = "${secrets}/secrets/bob/homepage-env.age";

      # Resource: https://www.authelia.com/configuration/methods/secrets/#environment-variables
      authelia-postgres-password.file = "${secrets}/secrets/bob/authelia/postgres-password.age";
      authelia-jwt-secret.file = "${secrets}/secrets/bob/authelia/jwt-secret.age";
      authelia-oidc-hmac-secret.file = "${secrets}/secrets/bob/authelia/hmac-secret.age";
      authelia-session-secret.file = "${secrets}/secrets/bob/authelia/session-secret.age";
      authelia-storage-encryption-key.file = "${secrets}/secrets/bob/authelia/storage-encryption-key.age";
      authelia-ldap-password.file = "${secrets}/secrets/bob/authelia/ldap-password.age";

      lldap-jwt-secret.file = "${secrets}/secrets/bob/lldap/jwt-secret.age";
      lldap-user-pass.file = "${secrets}/secrets/bob/lldap/user-pass.age";
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

    programs = {
      git.enable = true;
      htop.enable = true;

      tmux = {
        enable = true;
        escapeTime = 1;
        clock24 = true;
        baseIndex = 1;
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
        curl
        jq
        ldns
        ripgrep
        rsync
        tree
      ];
    };

    networking = {
      hostName = "bob";
      firewall.enable = true;
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

      authentication = {
        enable = true;

        subdomains = {
          auth = "auth";
          ldap = "ldap";
        };

        baseDomain = domain;
        ldapBaseDN = "dc=exocomet-hippocampus,dc=ts,dc=net";
      };

      homepage = {
        enable = true;
        inherit domain;
      };

      calibre-web = {
        enable = true;
        domain = "calibre.${domain}";
        libraryDir = "${mediaDir}/ebooks";
      };

      navidrome = {
        enable = true;
        domain = "navidrome.${domain}";
        musicDir = "${mediaDir}/music";
      };
    };
  };
}
