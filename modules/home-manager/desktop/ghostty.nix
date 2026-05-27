{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "dark:Catppuccin Macchiato,light:Catppuccin Latte";
      command = lib.getExe pkgs.fish;
      maximize = true;
    };
  };
}
