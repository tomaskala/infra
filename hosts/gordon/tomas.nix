{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/fish.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/neovim.nix
    ../../modules/home-manager/programs.nix
    ../../modules/home-manager/ssh.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/yt-dlp.nix
  ];

  config = {
    xdg.enable = true;

    home = {
      stateVersion = "24.05";
      homeDirectory = "/Users/tomas";

      file."${config.home.homeDirectory}/.config/ghostty/config".text = ''
        theme = dark:Catppuccin Macchiato,light:Catppuccin Latte

        command = ${lib.getExe pkgs.fish}
        macos-icon = retro

        # The size gets clamped to the screen size, so this maximizes new windows.
        window-width = 10000
        window-height = 10000

        keybind = global:cmd+backquote=toggle_quick_terminal
      '';
    };
  };
}
