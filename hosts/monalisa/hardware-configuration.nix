{ config, lib, pkgs, ... }:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "uas"
        "sd_mod"
        "aesni_intel"
        "cryptd"
        "dm-raid"
      ];
      kernelModules = [ ];
      supportedFilesystems = [ "zfs" ];
    };
    kernelModules = [ "kvm-intel" ];
    loader = {
      grub = {
        enable = true;
        version = 2;
        # One of these 2 SSDs in md raid1
        device = "/dev/disk/by-id/ata-KINGSTON_SV300S37A60G_50026B775B06CEC5";
        #device = "/dev/disk/by-id/ata-KINGSTON_SV300S37A60G_50026B775C03D7BA";

        # Enable grub over serial (as well as the graphical console)
        extraConfig = ''
          serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
          terminal_output console serial
          terminal_input console serial
        '';
      };
    };
    supportedFilesystems = [ "zfs" ];
  };

  fileSystems."/" =
    { device = "/dev/os/root";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/os/swap"; }
    ];

  # Set to the result of `nproc --all`
  # This is the max amount of concurrent jobs the server will use
  # to build Nix stuff
  nix.maxJobs = 8;
  powerManagement.cpuFreqGovernor = "performance";
}