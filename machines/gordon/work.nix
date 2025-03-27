{ pkgs, secrets, ... }:

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
    file = "${secrets}/secrets/other/gordon/work-ssh-config.age";
    path = "/Users/tomas/.ssh/config.d/work";
    owner = "tomas";
  };

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
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };

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
