{
  home.shell.enableShellIntegration = true;

  programs = {
    bat = {
      enable = true;

      config = {
        theme-light = "Catppuccin Latte";
        theme-dark = "Catppuccin Macchiato";
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
