{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence/master";
    vps-admin-os.url = "github:vpsfreecz/vpsadminos";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    suckless = {
      url = "github:tomaskala/suckless";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    unbound-blocker = {
      url = "github:tomaskala/unbound-blocker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-hardware, impermanence, vps-admin-os, agenix
    , home-manager, suckless, unbound-blocker, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      commonConfig = {
        config = {
          system.stateVersion = "23.05";

          # Pin the nixpkgs flake to the same exact version used to build
          # the system. This has two benefits:
          # 1. No version mismatch between system packages and those
          #    brought in by commands like 'nix shell nixpkgs#<package>'.
          # 2. More efficient evaluation, because many dependencies will
          # already be present in the Nix store.
          nix.registry.nixpkgs.flake = nixpkgs;
        };
      };

      forOneSystem = f: system:
        f (import nixpkgs {
          inherit system;
          overlays = [
            (_: _: {
              st = suckless.packages.${system}.st;
              unbound-blocker = unbound-blocker.packages.${system}.default;
            })
          ];
        });

      forAllSystems = f: nixpkgs.lib.genAttrs systems (forOneSystem f);
    in {
      nixosConfigurations = {
        whitelodge = let system = "x86_64-linux";
        in nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = forOneSystem (pkgs: pkgs) system;
          modules = [
            ./machines/whitelodge/configuration.nix
            commonConfig
            agenix.nixosModules.default
            vps-admin-os.nixosConfigurations.container
          ];
        };

        bob = let system = "aarch64-linux";
        in nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = forOneSystem (pkgs: pkgs) system;
          modules = [
            ./machines/bob/configuration.nix
            commonConfig
            nixos-hardware.nixosModules.raspberry-pi-4
            agenix.nixosModules.default
          ];
        };

        cooper = let system = "x86_64-linux";
        in nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = forOneSystem (pkgs: pkgs) system;
          modules = [
            ./machines/cooper/configuration.nix
            commonConfig
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen2
            impermanence.nixosModules.impermanence
            agenix.nixosModules.default
            home-manager.nixosModules.default
            { home-manager.useGlobalPkgs = true; }
          ];
        };
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            deadnix
            nixfmt
            statix
            agenix.packages.${system}.agenix
          ];
        };

        tf = pkgs.mkShell { packages = [ pkgs.opentofu ]; };
      });

      formatter = forAllSystems (pkgs:
        pkgs.writeShellApplication {
          name = "nixfmt";
          runtimeInputs = with pkgs; [ findutils nixfmt ];
          text = ''
            find . -type f -name '*.nix' -exec nixfmt {} \+
          '';
        });

      checks = forAllSystems (pkgs: {
        deadnix = pkgs.callPackage ./checks/deadnix.nix { };
        statix = pkgs.callPackage ./checks/statix.nix { };
        nixfmt = pkgs.callPackage ./checks/nixfmt.nix { };
      });
    };
}
