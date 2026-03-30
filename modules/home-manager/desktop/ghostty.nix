{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "dark:Catppuccin Macchiato,light:Catppuccin Latte";
      command = lib.getExe pkgs.unstable.fish;
      maximize = true;
      keybind = "global:cmd+backquote=toggle_quick_terminal";
    };
  };
}
