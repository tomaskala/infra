{ lib, pkgs, ... }:

{
  environment.systemPackages =
    with pkgs;
    [
      # System utilities
      coreutils
      diffutils
      gawk
      gnugrep
      gnused
      gnutar
      jq
      ripgrep
      rsync
      tree

      # Networking
      ldns
      nmap
      openssl
      whois
    ]
    ++ (lib.optional (pkgs.stdenv.hostPlatform.system != "aarch64-darwin") pkgs.curl);
}
