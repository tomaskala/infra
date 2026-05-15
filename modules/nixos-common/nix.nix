{ pkgs, inputs, ... }:

{
  nixpkgs.overlays = [
    (_: prev: {
      unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
      inherit (prev.lixPackageSets.latest)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena
        ;
    })
  ];

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;
    package = pkgs.lixPackageSets.latest.lix;

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
