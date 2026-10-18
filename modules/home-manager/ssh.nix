{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    extraConfig = /* sshconfig */ ''
      IgnoreUnknown UseKeychain
      UseKeychain yes
    '';

    settings = {
      "*" = {
        identitiesOnly = true;
        addKeysToAgent = "yes";
        serverAliveInterval = 60;
      };

      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
      };

      # Let Tailscale resolve the hostname.
      bob = {
        user = "tomas";
        identityFile = "~/.ssh/id_ed25519_bob";
      };

      seedbox = {
        user = "return9826";
        hostname = "nexus.usbx.me";
        identityFile = "~/.ssh/id_ed25519_seedbox";
      };
    };
  };
}
