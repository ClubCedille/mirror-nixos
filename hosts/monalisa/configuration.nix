{ lib, pkgs, ... }:

{
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  location = {
    # Montreal
    latitude = 45.50884;
    longitude = -73.58781;
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
  };
  # Use sudo with SSH agent
  security.pam.enableSSHAgentAuth = true;
}