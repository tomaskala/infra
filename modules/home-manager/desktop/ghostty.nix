{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "dark:Catppuccin Macchiato,light:Catppuccin Latte";
      cursor-invert-fg-bg = true;

      command = lib.getExe pkgs.fish;
      macos-icon = "retro";

      # The size gets clamped to the screen size, so this maximizes new windows.
      window-width = 10000;
      window-height = 10000;
    };
  };
}
