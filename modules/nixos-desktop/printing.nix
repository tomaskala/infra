{ pkgs, ... }:

{
  services = {
    avahi = {
      enable = true;
      openFirewall = true;
    };

    printing = {
      enable = true;

      drivers = with pkgs; [
        cups-browsed
        cups-filters
      ];
    };
  };
}
