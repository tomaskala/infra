{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    serverAliveInterval = 60;
    controlPath = "~/.ssh/master-%n:%p";

    extraConfig = # sshconfig
      ''
        IgnoreUnknown UseKeychain
        UseKeychain yes
      '';

    matchBlocks = {
      "github.com" = {
        user = "tomaskala";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_github";
      };

      # Let Tailscale resolve the hostname.
      bob = {
        user = "tomas";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_bob";
      };

      seedbox = {
        user = "return9826";
        hostname = "nexus.usbx.me";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_seedbox";
      };
    };
  };
}
