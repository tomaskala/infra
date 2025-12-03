{ lib, ... }:

{
  services = {
    xserver = {
      enable = true;

      displayManager.gdm = {
        enable = true;
        wayland = true;
      };

      desktopManager.gnome.enable = true;
    };

    gnome.gcr-ssh-agent.enable = lib.mkForce false;
  };
}
