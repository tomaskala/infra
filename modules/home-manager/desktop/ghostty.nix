{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "dark:Modus Vivendi,light:Modus Operandi";
      command = lib.getExe pkgs.fish;
      maximize = true;
    };
  };
}
