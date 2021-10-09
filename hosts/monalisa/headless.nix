/*

The role of this file is to reduce the total size of the system by disabling
non-essential packages and tools (all graphical applications for instance).

*/
{ lib, ... }:

{
  boot.vesa = false;

  # Don't start a tty on the serial consoles.
  systemd.services."serial-getty@ttyS0".enable = true;
  systemd.services."serial-getty@ttyS1".enable = true;
  systemd.services."serial-getty@ttyS2".enable = true;
  systemd.services."serial-getty@ttyS3".enable = true;
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@".enable = false;

  # Since we can't manually respond to a panic, just reboot.
  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];

  # Don't allow emergency mode, because we don't have a console.
  systemd.enableEmergencyMode = false;

  # Being headless, we don't need a GRUB splash image.
  boot.loader.grub.splashImage = null;
  
  # Disable graphical applications
  environment.noXlibs = true;

  # udisks is a daemon to allow unprivileged mounting of usb harddisks/keys
  # we won't need it
  services.udisks2.enable = false;

  documentation.enable = false;
  documentation.nixos.enable = false;
}
