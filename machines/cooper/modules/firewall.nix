{
  networking.firewall.enable = true;

  networking.nftables = {
    enable = true;
    checkRuleset = true;
  };
}