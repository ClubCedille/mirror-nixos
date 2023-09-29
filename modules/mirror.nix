{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.cedille.services.mirrors;

  # Systemd services hardening settings
  serviceConfig' = {
    CapabilityBoundingSet = [ "" ];
    DeviceAllow = [ "" ];
    DynamicUser = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    PrivateDevices = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProcSubset = "pid";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
    UMask = "0077";
  };

  /*
    Wrapper around `mkIf` to enable/disable a distribution configuration.

    How to use this:
    ```
      ifDistroEnabled "debian" (cfg: { something = cfg.mirrorDirectory; })
    ```
    The second parameter is a function that returns a Nix module.
    So the function could return a path, an attribute set or another function
    that accepts the regular `{ config, lib, pkgs, ... }`.
  */
  ifDistroEnabled = distro: module:
    mkIf cfg.distros."${distro}".enable
      (if builtins.isFunction module
      then (module cfg.distros."${distro}")
      else module);

  /*
    How to use this:
    ```
      mkDistro "my cool Linux distro" {
        extra-option-1 = mkOption {
          type = types.str;
          default = "something";
        };
      }
    ```
  */
  mkDistro = name: options: {
    enable = mkEnableOption "${name} mirrors";

    mirrorDirectory = mkOption {
      type = types.path;
      example = "/media/mirror/distribution";
      description = ''
        The directory where to save the ${name} distribution's files.
      '';
    };

    stateDirectory = mkOption {
      type = types.path;
      example = "/var/lib/distribution";
      description = ''
        The directory where to save the state and other
        miscellaneous files for the update scripts of ${name} distribution.
      '';
    };

    configuration = mkOption {
      type = types.nullOr (types.either (types.lines) (types.attrsOf types.str));
      default = null;
      description = ''
        Content of the configuration file for the updatescripts for the ${name} distribution.
      '';
    };

    configurationFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File containing the configuration for the update scripts for the ${name} distribution.
      '';
    };
  } // options;
in {

  options.cedille.services.mirrors = {
    enable = mkEnableOption "CEDILLE mirrors";

    distros.archlinux = mkDistro "Arch Linux" { };

    distros.debian = mkDistro "Debian" { };

    distros.manjaro = mkDistro "Manjaro" { };

    distros.mint = mkDistro "Linux Mint" { };

    distros.mxlinux = mkDistro "MX Linux" { };

    distros.ubuntu = mkDistro "Ubuntu" { };
  };

  config = mkIf cfg.enable (mkMerge [
    (ifDistroEnabled "debian" (cfg: {
      assertions = [{
        assertion = (cfg.configuration == null) != (cfg.configurationFile == null);
        message = ''
          Either the option "configuration" or "configurationFile" must be
          specified for "cedille.services.mirrors.distros.debian"
        '';
      }];

      systemd.services.sync-mirror-debian = {
        # 00:17, 04:17, 08:17, 12:17, 16:17 and 20:17 every day
        startAt = "*-*-* 0/6:17:00";
        environment = {
          # Recommended by the upstream Debian ftpsync project
          # See the README: https://salsa.debian.org/mirror-team/archvsync/
          LANG = "POSIX";
          LC_ALL = "POSIX";
        };
        script = let
          config =
            if cfg.configurationFile != null
            # This won't work if the file is not named "ftpsync.conf"
            then dirOf cfg.configurationFile
            else pkgs.writeTextDir "ftpsync.conf" (lib.generators.toKeyValue { } cfg.configuration);
          ftpsync = pkgs.ftpsync.override {
            # Must be a path to the folder containing an ftpsync.conf
            ftpsync-conf = toString config;
            ftpsync-dir = cfg.stateDirectory;
          };
        in "${ftpsync}/bin/ftpsync sync:all";
        serviceConfig = serviceConfig';
      };
    }))

    (ifDistroEnabled "mint" (cfg: {
      systemd.services.sync-mirror-linux-mint-packages = {
        # 00:20 and 12:20 every day
        startAt = "*-*-* 0/12:20:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/mint_packages.sh";
        serviceConfig = serviceConfig';
      };
      systemd.services.sync-mirror-linux-mint-releases = {
        # 22:02 every day
        startAt = "*-*-* 22:02:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/mint_releases.sh";
        serviceConfig = serviceConfig';
      };
    }))

    (ifDistroEnabled "ubuntu" (cfg: {
      systemd.services.sync-mirror-ubuntu-packages = {
        # 00:51, 06:51, 12:51 and 18:51 every day
        startAt = "*-*-* 0/4:51:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/ubuntu_packages.sh";
        serviceConfig = serviceConfig';
      };
      systemd.services.sync-mirror-ubuntu-releases = {
        # 03:51 every day
        startAt = "*-*-* 3:51:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/ubuntu_releases.sh";
        serviceConfig = serviceConfig';
      };
    }))

    (ifDistroEnabled "archlinux" (cfg: {
      systemd.services.sync-mirror-arch = {
        # 00:36, 02:36, 04:36, 06:36, 10:36, 12:36, 14:36, 16:36, 18:36, 20:36 and 22:36 every day
        startAt = "*-*-* 0/2:36:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/arch.sh";
        serviceConfig = serviceConfig';
      };
    }))

    (ifDistroEnabled "manjaro" (cfg: {
      systemd.services.sync-mirror-manjaro = {
        # 00:43, 04:43, 08:43, 12:43, 16:43 and 20:43 every day
        startAt = "*-*-* 0/6:43:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/manjaroreposync.sh";
        serviceConfig = serviceConfig';
      };
    }))

    (ifDistroEnabled "mxlinux" (cfg: {
      systemd.services.sync-mirror-mx-linux = {
        # 00:30 and 12:30 every day
        startAt = "*-*-* 0/12:30:00";
        environment = {
        };
        script = "${pkgs.cedille-mirror}/bin/mx-linux_packages.sh";
        serviceConfig = serviceConfig';
      };
    }))
  ]);
}
