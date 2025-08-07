{
  config,
  pkgs,
  secrets,
  ...
}:

let
  domain = "whitelodge.exocomet-hippocampus.ts.net";
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

    system = {
      stateVersion = "25.05";

      autoUpgrade = {
        enable = true;
        operation = "switch";
        flake = "github:tomaskala/infra";

        # Run after the automatic flake.lock update configured in Github Actions.
        dates = "Sun *-*-* 03:00:00";
      };
    };

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
      tomas-password.file = "${secrets}/secrets/whitelodge/users/tomas.age";
      root-password.file = "${secrets}/secrets/whitelodge/users/root.age";
      tailscale-api-key = "${secrets}/secrets/whitelodge/tailscale-api-key.age";
      homepage-env = "${secrets}/secrets/whitelodge/homepage-env.age";

      # Resource: https://www.authelia.com/configuration/methods/secrets/#environment-variables
      authelia-postgres-password = "${secrets}/secrets/whitelodge/authelia/postgres-password.age";
      authelia-jwt-secret = "${secrets}/secrets/whitelodge/authelia/jwt-secret.age";
      authelia-oidc-hmac-secret = "${secrets}/secrets/whitelodge/authelia/hmac-secret.age";
      authelia-oidc-issuer-private-key = "${secrets}/secrets/whitelodge/authelia/oidc-issuer-private-key.age";
      authelia-session-secret = "${secrets}/secrets/whitelodge/authelia/session-secret.age";
      authelia-storage-encryption-key = "${secrets}/secrets/whitelodge/authelia/storage-encryption-key.age";
      authelia-ldap-password = "${secrets}/secrets/whitelodge/authelia/ldap-password.age";

      lldap-jwt-secret = "${secrets}/secrets/whitelodge/lldap/jwt-secret.age";
      lldap-user-pass = "${secrets}/secrets/whitelodge/lldap/user-pass.age";
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
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvN19BcNTeaVAF291lBG0z9ROD6J91XAMyy+0VP6CdL cooper2whitelodge"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRpAi2U+EW2dhKv/tu2DVJPNZnrqgQway2CSAs38tFl blacklodge2whitelodge"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICnSCqYOxP/hkkgquZ8XM5OvssH7BpHUouGS5TvEIvnC gordon2whitelodge"
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
      hostName = "whitelodge";
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
