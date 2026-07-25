{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "dark:Nvim Dark,light:Nvim Light";
      command = lib.getExe pkgs.fish;
      maximize = true;
    };
  };
}
