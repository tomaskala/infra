{ lib, pkgs, ... }:

{
  programs.zellij = {
    enable = true;

    settings = {
      theme = "catppuccin-macchiato";
      show_startup_tips = false;
      default_shell = lib.getExe pkgs.fish;
    };

    layouts = {
      two = ''
        layout {
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }

          pane split_direction="vertical" {
            pane
            pane
          }

          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }
        }
      '';

      three = ''
        layout {
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }

          pane split_direction="vertical" {
            pane
            pane split_direction="horizontal" {
              pane
              pane
            }
          }

          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }
        }
      '';
    };
  };
}
