{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../home/fish.nix
    ../../home/git.nix
    ../../home/neovim.nix
    ../../home/programs.nix
    ../../home/ssh.nix
    ../../home/starship.nix
    ../../home/tmux.nix
    ../../home/yt-dlp.nix
    ../../intranet
  ];

  config.home = {
    stateVersion = "24.05";
    homeDirectory = "/Users/tomas";

    file."${config.home.homeDirectory}/.config/ghostty/config".text = ''
      theme = dark:catppuccin-macchiato,light:catppuccin-latte
      command = ${lib.getExe pkgs.fish}
    '';
  };
}
