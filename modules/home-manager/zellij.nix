{ lib, pkgs, ... }:

{
  programs.zellij = {
    enable = true;

    settings = {
      default_shell = lib.getExe pkgs.fish;
      show_startup_tips = false;
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
