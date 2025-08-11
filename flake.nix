{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/tomaskala/infra-secrets";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        agenix.follows = "agenix";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      catppuccin,
      nix-darwin,
      home-manager,
      lanzaboote,
      agenix,
      treefmt-nix,
      secrets,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      commonConfig = {
        nixpkgs.overlays = [
          (final: prev: {
            unstable = nixpkgs-unstable.legacyPackages.${prev.system};
            infra = import ./infra { inherit (final.pkgs) lib; };
          })
        ];

        nix = {
          # Pin the nixpkgs flake to the same exact version used to build
          # the system. This has two benefits:
          # 1. No version mismatch between system packages and those
          #    brought in by commands like 'nix shell nixpkgs#<package>'.
          # 2. More efficient evaluation, because many dependencies will
          # already be present in the Nix store.
          registry.nixpkgs.flake = nixpkgs;

          settings = {
            auto-optimise-store = true;
            experimental-features = [
              "nix-command"
              "flakes"
            ];
          };
        };
      };

      treefmtConfig = {
        projectRootFile = "flake.nix";

        programs = {
          mdformat.enable = true;
          nixfmt.enable = true;
          yamlfmt.enable = true;
        };

        settings = {
          global.excludes = [ "LICENSE" ];
          formatter.mdformat.options = [ "--number" ];
        };
      };

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosConfigurations = {
        bob = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            commonConfig
            ./hosts/bob/configuration.nix
            agenix.nixosModules.default
            # nixos-hardware unfortunately lacks a preset for this particular NUC model.
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-pc
            nixos-hardware.nixosModules.common-pc-ssd
            {
              services.thermald.enable = true;
            }
          ];

          specialArgs = {
            inherit secrets;
          };
        };

        cooper = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            commonConfig
            ./hosts/cooper/configuration.nix
            catppuccin.nixosModules.catppuccin
            agenix.nixosModules.default
            lanzaboote.nixosModules.lanzaboote
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen2
          ];

          specialArgs = {
            inherit secrets;
          };
        };
      };

      darwinConfigurations = {
        gordon = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          modules = [
            commonConfig
            ./hosts/gordon/configuration.nix
            agenix.darwinModules.default
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.tomas = import ./hosts/gordon/tomas.nix;
              };
            }
          ];

          specialArgs = {
            inherit secrets;
          };
        };
      };

      homeConfigurations = {
        "tomas@cooper" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          modules = [
            commonConfig
            catppuccin.homeModules.catppuccin
            ./hosts/cooper/tomas.nix
          ];
        };

        "tomas@blacklodge" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          modules = [
            commonConfig
            catppuccin.homeModules.catppuccin
            agenix.homeManagerModules.default
            ./hosts/blacklodge/tomas.nix
          ];

          extraSpecialArgs = {
            inherit secrets;
          };
        };
      };

      formatter = forAllSystems (pkgs: treefmt-nix.lib.mkWrapper pkgs treefmtConfig);

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

        formatting = (treefmt-nix.lib.evalModule pkgs treefmtConfig).config.build.check self;
      });
    };
}
