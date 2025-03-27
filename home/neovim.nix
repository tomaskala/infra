{ pkgs, ... }:

{
  xdg.configFile = {
    "nvim/lsp/gopls.lua".text = # lua
      ''
        return {
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl", "gosum" },
          root_markers = {
            "go.mod",
            "go.work",
            ".git",
          },
        }
      '';

    "nvim/lsp/lua_ls.lua".text = # lua
      ''
        return {
          cmd = { "lua-language-server" },
          filetypes = { "lua" },
          root_markers = {
            ".luarc.json",
            ".luarc.jsonc",
            ".luacheckrc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
            ".git",
          },
          settings = {
            Lua = {
              diagnostics = {
                globals = {
                  "vim",
                },
              },
            },
          },
        }
      '';

    "nvim/lsp/nil_ls.lua".text = # lua
      ''
        return {
          cmd = { "nil" },
          filetypes = { "nix" },
          root_markers = {
            "flake.nix",
            ".git",
          },
          settings = {
            ["nil"] = {
              formatting = {
                command = { "nixfmt" },
              },
              nix = {
                flake = {
                  autoArchive = false,
                }
              },
            },
          },
        }
      '';

    "nvim/lsp/pyright.lua".text = # lua
      ''
        return {
          cmd = { "pyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_markers = {
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            "pyrightconfig.json",
            ".git",
          },
          settings = {
            pyright = {
              -- Using Ruff's import organizer.
              disableOrganizeImports = true,
            },
            python = {
              analysis = {
                -- Ignore all files for analysis to exclusively use Ruff for linting.
                ignore = { "*" },
              },
            },
          },
        }
      '';

    "nvim/lsp/ruff.lua".text = # lua
      ''
        return {
          cmd = { "ruff", "server" },
          filetypes = { "python" },
          root_markers = {
            "pyproject.toml",
            "ruff.toml",
            ".ruff.toml",
            ".git",
          },
        }
      '';
  };

  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;

    extraPackages = with pkgs; [
      gopls
      lua-language-server
      nil
      nixfmt-rfc-style
      pyright
      ruff
    ];

    plugins = with pkgs.vimPlugins; [
      {
        plugin = catppuccin-nvim;
        type = "lua";
        config = # lua
          ''
            require("catppuccin").setup({
              background = {
                light = "latte",
                dark = "macchiato",
              },
            })
            vim.cmd.colorscheme("catppuccin")
          '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = # lua
          ''
            require("lualine").setup({
              options = {
                theme = "catppuccin",
              },
              sections = {
                lualine_x = { "filetype" },
              },
            })
          '';
      }
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
      }
      {
        plugin = nvim-web-devicons;
        type = "lua";
      }
      {
        plugin = telescope-fzf-native-nvim;
        type = "lua";
      }
      {
        plugin = telescope-file-browser-nvim;
        type = "lua";
      }
      {
        plugin = telescope-nvim;
        type = "lua";
        config = # lua
          ''
            do
              local telescope_api = require("telescope.builtin")
              local opts = { noremap = true, silent = true }

              vim.keymap.set("n", "<C-p>", telescope_api.find_files, opts)
              vim.keymap.set("n", "<C-S-p>", telescope_api.live_grep, opts)
              vim.keymap.set("n", "<C-b>", telescope_api.buffers, opts)

              vim.keymap.set("n", "grr", telescope_api.lsp_references, opts)
              vim.keymap.set("n", "gd", function()
                telescope_api.lsp_definitions({ reuse_win = true })
              end, opts)
              vim.keymap.set("n", "gi", function()
                telescope_api.lsp_implementations({ reuse_win = true })
              end, opts)
              vim.keymap.set("n", "go", function()
                telescope_api.lsp_type_definitions({ reuse_win = true })
              end, opts)

              local telescope = require("telescope")
              telescope.load_extension("fzf")

              telescope.load_extension("file_browser")
              vim.keymap.set("n", "<C-h>", function()
                telescope.extensions.file_browser.file_browser({
                  path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
                  select_buffer = true,
                })
              end, opts)
              vim.keymap.set("n", "<C-S-h>", function()
                telescope.extensions.file_browser.file_browser()
              end, opts)
            end
          '';
      }
    ];

    extraLuaConfig = # lua
      ''
        vim.loader.enable()
        vim.g.mapleader = ","

        vim.opt.tabstop = 2
        vim.opt.softtabstop = 2
        vim.opt.shiftwidth = 2
        vim.opt.expandtab = true
        vim.opt.breakindent = true

        vim.opt.shortmess:append({ I = true })
        vim.opt.splitbelow = true
        vim.opt.splitright = true

        vim.opt.backup = false
        vim.opt.swapfile = false

        vim.opt.cursorline = true
        vim.opt.scrolloff = 3
        vim.opt.mousescroll = "ver:1,hor:6"
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.wildmode = { "longest:full", "full" }
        vim.opt.showmode = false
        vim.opt.completeopt = "menu,menuone,popup,fuzzy,noinsert"
        vim.opt.winborder = "rounded"

        vim.opt.ignorecase = true
        vim.opt.smartcase = true

        vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { noremap = true })
        vim.diagnostic.config({ virtual_text = true })

        do
          local configs = {}
          for _, v in ipairs(vim.api.nvim_get_runtime_file("lsp/*", true)) do
            local name = vim.fn.fnamemodify(v, ":t:r")
            table.insert(configs, name)
          end
          vim.lsp.enable(configs)
        end

        vim.api.nvim_create_autocmd("LspAttach", {
          desc = "Configure LSP",
          group = vim.api.nvim_create_augroup("lsp_config", { clear = true }),
          callback = function(args)
            -- Configure keybinds.
            local opts = { buffer = args.buf, noremap = true, silent = true }
            vim.keymap.set("n", "grf", "<cmd>lua vim.lsp.buf.format()<cr>", opts)

            -- Configure completions.
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client:supports_method("textDocument/completion") then
              vim.lsp.completion.enable(true, client.id, args.buf)
            end
          end,
        })

        vim.api.nvim_create_autocmd("FileType", {
          desc = "Start treesitter",
          group = vim.api.nvim_create_augroup("start_treesitter", { clear = true }),
          callback = function()
            pcall(vim.treesitter.start)
          end
        })

        vim.api.nvim_create_autocmd("FileType", {
          desc = "Go settings",
          pattern = "go",
          group = vim.api.nvim_create_augroup("golang", { clear = true }),
          callback = function(args)
            vim.opt_local.expandtab = false
            vim.opt_local.makeprg = "go build"
          end,
        })

        vim.api.nvim_create_autocmd("FileType", {
          desc = "Indent to 4 spaces",
          pattern = { "go", "python" },
          group = vim.api.nvim_create_augroup("indent_4_spaces", { clear = true }),
          callback = function()
            vim.opt_local.tabstop = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.shiftwidth = 4
          end,
        })

        vim.api.nvim_create_autocmd("FileType", {
          desc = "Plaintext settings",
          pattern = { "markdown", "text" },
          group = vim.api.nvim_create_augroup("plaintext", { clear = true }),
          callback = function()
            vim.opt_local.textwidth = 79
            vim.opt_local.formatoptions:append({ w = true })
            vim.opt_local.tabstop = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.shiftwidth = 2
          end,
        })
      '';
  };
}
