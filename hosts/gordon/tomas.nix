{
  imports = [
    ../../modules/home-manager/fish.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/neovim.nix
    ../../modules/home-manager/programs.nix
    ../../modules/home-manager/ssh.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/yt-dlp.nix
    ../../modules/home-manager/zellij.nix
    ../../modules/home-manager/desktop/ghostty.nix
  ];

  config = {
    xdg.enable = true;
    programs.ghostty.package = null;

    home = {
      stateVersion = "24.05";
      homeDirectory = "/Users/tomas";
    };
  };
}
