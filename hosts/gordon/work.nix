{ pkgs, ... }:

let
  work = pkgs.writeShellApplication {
    name = "work";
    runtimeInputs = with pkgs; [
      biome
      yarn
    ];
    text = ''
      die() {
        printf '%s\n' "$1" >&2 && exit 1
      }

      if [ "$#" -eq 0 ]; then
        die 'No arguments provided'
      fi

      cmd="$1"
      shift

      case "$cmd" in
        fmt)
          biome check --write --javascript-linter-enabled=false "$@"
          ;;
        test)
          yarn nx test "$@"
          ;;
        *)
          die "Unrecognized command: $cmd"
          ;;
      esac
    '';
  };
in
{
  homebrew = {
    masApps = {
      Slack = 803453959;
    };

    casks = [
      "tunnelblick"
    ];
  };

  age.secrets.work-ssh-config = {
    file = ../../secrets/gordon/work-ssh-config.age;
    path = "/Users/tomas/.ssh/config.d/work";
    owner = "tomas";
  };

  environment.systemPackages = with pkgs; [
    # NodeJS development
    biome
    nodejs
    typescript
    yarn

    # Python development
    poetry
    python3

    # Infrastructure
    hcloud

    # My utilities
    work
  ];

  home-manager.users.tomas = {
    xdg.configFile = {
      "nvim/lsp/biome.lua".text = # lua
        ''
          return {
            cmd = { "biome", "lsp-proxy" },
            filetypes = {
              "astro",
              "css",
              "graphql",
              "javascript",
              "javascriptreact",
              "json",
              "jsonc",
              "svelte",
              "typescript",
              "typescript.tsx",
              "typescriptreact",
              "vue",
            },
            root_markers = {
              "package.json",
              "biome.json",
              "biome.jsonc",
            },
          }
        '';

      "nvim/lsp/ts_ls.lua".text = # lua
        ''
          return {
            cmd = { "typescript-language-server", "--stdio" },
            filetypes = {
              "javascript",
              "javascriptreact",
              "javascript.jsx",
              "typescript",
              "typescriptreact",
              "typescript.tsx",
            },
            root_markers = {
              "tsconfig.json",
              "jsconfig.json",
              "package.json",
              ".git",
            },
            init_options = { hostInfo = "neovim" },
            on_attach = function(client)
              -- We format using biome instead of ts_ls.
              client.server_capabilities.documentFormattingProvider = false
            end,
          }
        '';
    };

    programs = {
      git.includes = [
        {
          condition = "gitdir:~/IPFabric/";
          contents.user.email = "tomas.kala@ipfabric.io";
        }
      ];

      neovim.extraPackages = with pkgs; [
        biome
        nodePackages.typescript-language-server
      ];

      ssh.includes = [ "/Users/tomas/.ssh/config.d/work" ];
    };
  };
}
