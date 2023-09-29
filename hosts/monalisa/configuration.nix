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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # NOTE: if the system does not exist yet, change to the latest NixOS version.
  system.stateVersion = "21.05"; # Did you read the comment?
}
