{
  imports = [
    ../../modules/home-manager/programs.nix
  ];

  config = {
    programs.bash.enable = true;

    home = {
      stateVersion = "25.05";
      homeDirectory = "/home/tomas";
    };
  };
}
