{ pkgs, ... }:

{
  imports = [
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

    programs.zsh.enable = true;

    home = {
      stateVersion = "24.05";
      username = "tomas";
      homeDirectory = "/home/tomas";

      packages = with pkgs; [
        # Development
        go
        gotools
        lua
        python3
        shellcheck

        # Media
        hugo
        wineWowPackages.stable

        # Networking
        curl
        ldns
        rsync
        wireguard-tools

        # Fonts
        nerd-fonts.fira-code
      ];
    };

    fonts.fontconfig.enable = true;

    catppuccin = {
      enable = true;
      accent = "mauve";
      flavor = "macchiato";
    };
  };
}
