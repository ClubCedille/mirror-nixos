{ lib, ... }:

{
  # Override the default network interfaces name that Systemd
  # assigns to the nodes
  systemd.network.links = {
    "eth0" = {
      matchConfig.MACAddress = "9c:5c:8e:51:70:bd";
      linkConfig.Name = "eth0";
    };
    "eth1" = {
      matchConfig.MACAddress = "9c:5c:8e:51:70:be";
      linkConfig.Name = "eth1";
    };
  };
  
  # Global network configuration
  networking = {
    useDHCP = false;
    interfaces.eth0.useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address= "142.137.247.132";
      prefixLength = 24;
    }];

    hostId = "507113d2"; # Randomly generated value
    hostName = "monalisa";
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
      # Un jour?
      # "2001:4860:4860::8888"
      # "2001:4860:4860::8844"
    ];

    firewall = {
      interfaces = {
        eth0.allowedTCPPorts = [ 22 80 443 ];
      };
      logRefusedConnections = true;
      logRefusedUnicastsOnly = true;
    };
  };

  services.lldpd.enable = true;
}