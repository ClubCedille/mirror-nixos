{ config, lib, pkgs, ... }:

let
  mirrorVhost = {
    enableACME = true;
    forceSSL = false;
    root = "${pkgs.cedille-mirror}/share/webroot";
  };
in
{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."mirror.cedille.club" = mirrorVhost;
    virtualHosts."miroir.cedille.club" = mirrorVhost;
  };

  security.acme.acceptTerms = true;
  security.acme.certs = {
    "mirror.cedille.club".email = "clubcedille@gmail.com";
    "miroir.cedille.club".email = "clubcedille@gmail.com";
  };
}