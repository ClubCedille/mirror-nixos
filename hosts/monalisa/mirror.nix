{
  lib,
  pkgs,
  ...
}: let
  mirrorVhost = {
    enableACME = true;
    forceSSL = false;
    root = "${pkgs.cedille-mirror}/share/webroot";
  };
  domains = ["mirroir.cedille.club" "miroir.cedille.club"];
  forAllDomains = value: builtins.listToAttrs (map (name: {inherit name value;}) domains);
in {
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = forAllDomains mirrorVhost;
  };

  security.acme.acceptTerms = true;
  security.acme.certs = forAllDomains {email = "clubcedille@gmail.com";};

  cedille.services.mirrors = {
    enable = true;
    inherit domains;
    distros.debian = rec {
      enable = true;
      mirrorDirectory = "/media/mirror/debian/packages";
      stateDirectory = "/var/lib/mirror/debian";
      # Every 4 hours on average
      frequency = "3hr 30min";
      randomDelay = "1hr";
      # We need the settings to be within double-quotes
      configuration = lib.mapAttrs (_: v: ''"${v}"'') {
        "ARCH_INCLUDE" = "i386 amd64";
        # ARCH_INCLUDE = "arm64 arm arm64 armel armhf i386 amd64";
        "TRACEHOST" = "$(hostname)";
        "RSYNC_HOST" = "ftp2.ca.debian.org";
        "RSYNC_PATH" = "debian";
        "TO" = mirrorDirectory;
        "MIRRORNAME" = "$(hostname)";
        #"MAILTO" = "root";

        ## Hook scripts can be run at various places during the sync.
        ## Leave them blank if you don't want any
        ## Hook1: After lock is acquired, before first rsync
        ## Hook2: After first rsync, if successful
        ## Hook3: After second rsync, if successful
        ## Hook4: Right before leaf mirror triggering
        ## Hook5: After leaf mirror trigger, only if we have slave mirrors (HUB=true)
        ##
        ## Note that Hook3 and Hook4 are likely to be called directly after each other.
        ## Difference is: Hook3 is called *every* time the second rsync was successful,
        ## but even if the mirroring needs to re-run thanks to a second push.
        ## Hook4 is only effective if we are done with mirroring.
        # "HOOK1" = toString (pkgs.writers.writePython3 "debian-mirror-hook1" { libraries = [ ]; } ''

        # '');
      };
    };
  };
}
