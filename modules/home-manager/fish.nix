{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = # fish
      ''
        set -gx EMAIL me@tomaskala.com
        set -gx EDITOR nvim

        set -gx XDG_CACHE_HOME ~/.cache
        set -gx XDG_CONFIG_HOME ~/.config
        set -gx XDG_DATA_HOME ~/.local/share

        set -gx GOPATH "$XDG_DATA_HOME/go"
        set -gx GOBIN ~/.local/bin

        set -g fish_greeting
        fish_add_path ~/.local/bin
      '';

    shellAliases = {
      diff = "${pkgs.diffutils}/bin/diff --color=auto";
      grep = "${pkgs.gnugrep}/bin/grep --color=auto";
      ll = "ls -l";
      lla = "ls -la";
      ls = "${pkgs.coreutils}/bin/ls -FNh --color=auto --group-directories-first";
      vim = "nvim";
      lg = "lazygit";
    };
  };
}
