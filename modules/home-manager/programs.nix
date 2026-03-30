{ pkgs, ... }:

{
  home = {
    shell.enableShellIntegration = true;

    packages = with pkgs; [
      jless
    ];
  };

  programs = {
    bat = {
      enable = true;

      config = {
        theme-light = "Catppuccin Latte";
        theme-dark = "Catppuccin Macchiato";
      };
    };

    lazygit = {
      enable = true;
      settings = {
        gui.nerdFontsVersion = "3";
        git.parseEmoji = true;
      };
    };

    fd.enable = true;
    fzf.enable = true;
    home-manager.enable = true;
    htop.enable = true;
    jq.enable = true;
    ripgrep.enable = true;
  };
}
