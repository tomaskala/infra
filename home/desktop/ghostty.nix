{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "dark:catppuccin-macchiato,light:catppuccin-latte";
      cursor-invert-fg-bg = true;

      command = lib.getExe pkgs.unstable.fish;
      macos-icon = "retro";

      # The size gets clamped to the screen size, so this maximizes new windows.
      window-width = 10000;
      window-height = 10000;
    };
  };
}
