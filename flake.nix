{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix/main";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      nix-darwin,
      home-manager,
      disko,
      lanzaboote,
      agenix,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosConfigurations = {
        bob = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/bob/configuration.nix
            agenix.nixosModules.default
            disko.nixosModules.default
            # nixos-hardware unfortunately lacks a preset for this particular NUC model.
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-pc
            nixos-hardware.nixosModules.common-pc-ssd
            home-manager.nixosModules.home-manager
          ];
        };

        cooper = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/cooper/configuration.nix
            agenix.nixosModules.default
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen2
            lanzaboote.nixosModules.lanzaboote
            home-manager.nixosModules.home-manager
          ];
        };
      };

      darwinConfigurations = {
        gordon = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/gordon/configuration.nix
            agenix.darwinModules.default
            home-manager.darwinModules.home-manager
          ];
        };
      };

      homeConfigurations = {
        "tomas@blacklodge" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };

          modules = [
            ./hosts/blacklodge/tomas.nix
            agenix.homeManagerModules.default
          ];
        };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      checks = forAllSystems (pkgs: {
        deadnix = pkgs.runCommandLocal "check-deadnix" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
          set -e
          deadnix --fail ${self}
          touch $out
        '';

        statix = pkgs.runCommandLocal "check-statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
          set -e
          statix check ${self}
          touch $out
        '';
      });
    };
}
