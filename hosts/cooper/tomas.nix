{ lib, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/desktop/ghostty.nix
    ../../modules/home-manager/desktop/zathura.nix
    ../../modules/home-manager/fish.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/mpv.nix
    ../../modules/home-manager/neovim.nix
    ../../modules/home-manager/programs.nix
    ../../modules/home-manager/ssh.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/yt-dlp.nix
  ];

  config = {
    nix.package = pkgs.nix;

    home = {
      stateVersion = "24.05";
      username = "tomas";
      homeDirectory = "/home/tomas";
    };

    catppuccin = {
      enable = true;
      accent = "mauve";
      flavor = "macchiato";

      # Catppuccin for GTK has been discontinued.
      gtk.enable = lib.mkForce false;
    };

    xdg.desktopEntries.openmw = {
      name = "OpenMW";
      type = "Application";
      exec = "${pkgs.gamemode}/bin/gamemoderun ${pkgs.openmw}/bin/openmw-launcher";
      terminal = false;
      categories = [ "Game" ];
    };
  };
}
