{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) attrNames concatMap elem isString mkEnableOption mkIf mkMerge mkOption optional types;
  # TODO: Why is this not `config.services.cedille-mirrors`?
  cfg = config.cedille.services.mirrors;

  # NOTE: if you want to support more distribution types,
  #       make sure to also support them in mkDistroScript
  supportedDistroTypes = ["debian" "ubuntu" "arch"];

  # How this should work:
  # - Some kind of shared options between mirror types
  # - Type-specific options
  # How can the specific and shared options be separated?
  # What about partially shared options?

  # Systemd services hardening settings
  serviceConfig' = {
    CapabilityBoundingSet = [""];
    DeviceAllow = [""];
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
    RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = ["@system-service" "~@privileged" "~@resources"];
    UMask = "0077";
  };

  # TODO: make scripts instead of nothing
  mkDistroScript = {
    name,
    variant,
  }:
    assert elem variant ["iso" "packages" "releases"]; let
      distroType = cfg.distros.${name}.type;
    in
      if distroType == "debian"
      then
        if variant == "packages"
        then
          # FIXME: Add environment variables for settings and config of ftpsync
          # NOTE: woa, when there's "environment" in a comment above a string, the highlighting gets weird.
          ''
            ${pkgs.ftpsync}/bin/ftpsync sync:all
          ''
        else if variant == "iso"
        then throw "TODO"
        else throw "Unsupported variant '${variant}' for debian-like mirror '${name}'"
      else if distroType == "ubuntu"
      then
        if variant == "packages"
        then throw "TODO"
        else if variant == "iso"
        then throw "TODO"
        else if variant == "releases"
        then throw "TODO"
        else throw "Unsupported variant '${variant}' for ubuntu-like mirror '${name}'"
      else if distroType == "arch"
      then
        if variant == "packages"
        then throw "TODO"
        else if variant == "iso"
        then throw "TODO"
        else throw "Unsupported variant '${variant}' for arch-like mirror '${name}'"
      else throw "Support for distro ${name} is not yet implemented. This is a bug and needs to be fixed.";

  # Build the configuration for a single distro from its name
  mkSystemdDistroConfig = {
    name,
    variant ? "packages",
  }:
  # Same names in both options and config
    assert builtins.hasAttr name cfg.distros; {
      systemd.services."sync-mirror-${name}-${variant}" = {
        environment = {
          # Recommended by the upstream Debian ftpsync project
          # See the README: https://salsa.debian.org/mirror-team/archvsync/
          # It also seems like a good default for the other mirrors
          LANG = "POSIX";
          LC_ALL = "POSIX";
        };
        script = mkDistroScript {inherit name variant;};
        serviceConfig = let
          mirrorDirectory = cfg.distros.${name}.mirrorDirectory;
        in
          serviceConfig'
          // {
            AssertPathIsDirectory = mirrorDirectory;
            AssertPathIsReadWrite = mirrorDirectory;
            ReadWritePaths = [mirrorDirectory];
            RequiresMountsFor = mirrorDirectory;
          };
      };
      systemd.timers."sync-mirror-${name}" = {
        # TODO: Test this
        timerConfig = {
          # FIXME: what about when the system boots? Do we only rely on the randomDelay?
          OnUnitActiveSec = cfg.distros.${name}.frequency;
          RandomDelaySec = cfg.distros.${name}.randomDelay;
        };
      };
    };
  mkNginxDistroConfig = name: {
    nginx.virtualHosts = let
      value = assert !(lib.hasInfix "/" name); {
        locations."/${name}/" = {
          # TODO!: serve the correct director(y|ies)
        };
      };
    in
      builtins.listToAttrs (map (name: {inherit name value;}) (
        if isString cfg.domains
        then [cfg.domains]
        else cfg.domains
      ));
  };
in {
  options.cedille.services.mirrors = {
    enable = mkEnableOption "CEDILLE mirrors";

    domains = mkOption {
      type = types.either types.str (types.listOf types.str);
      example = "example.org";
      description = ''
        The domain name(s) used for the nginx virtualHost(s).
        This can either be a single domain name or a list of domain names.
      '';
    };

    distros = mkOption {
      type = types.attrsOf (types.submodule ({
        config,
        name,
      }: {
        options = {
          enable = mkEnableOption "${name} mirrors";

          configureNginx = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to configure nginx for this mirror.";
          };

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

          frequency = mkOption {
            type = types.str;
            example = "2h 30min";
            description = lib.mdDoc ''
              The frequency at which the mirror will fetch updates for the ${name} distribution.
              The syntax is described in `systemd.time(5)`
            '';
          };

          randomDelay = mkOption {
            type = types.str;
            default = "1hr";
            example = "30min";
            description = lib.mdDoc ''
              The maximum random delay added between the invocations of the update scripts for the ${name} distribution.
              The syntax is described in `systemd.time(5)`
            '';
          };

          type = mkOption {
            type = types.enum supportedDistroTypes;
            description = lib.mdDoc ''
              The type of the mirror.
              This affects which script is ran.
              For example, the "debian" type uses `ftpsync`,
              while the others use a more custom `rsync` script.
            '';
          };
          # NOTE: assuming (almost) ALL of the config is the same for ISO images
          iso-images = mkOption {
            type = types.submodule {
              options = {
                enable = mkEnableOption "ISO images mirroring for ${name}";
              };
            };
          };

          # FIXME: what about ISO files? Should these be mirrored too?
          architectures = mkOption {
            # TODO: type-check the architectures (but not all distributions call them the same)
            type = types.listOf types.str;
            # TODO: add example
            description = ''
              The CPU architectures of the mirrored archives.
              This is specific to each distribution.
              They don't necessarily all use the same names.
            '';
          };
          upstream = mkOption {
            type = types.submodule {
              options = {
                domain = mkOption {
                  type = types.str;
                  description = ''
                    The domain name of the upstream rsync source that will be mirrored.
                  '';
                };
                path = mkOption {
                  type = types.str;
                  # FIXME: What should be the default here?
                  default = "";
                  # TODO: should this always end or not end with "/"? Add examples!
                  description = ''
                    The remote path mirrored with rsync
                  '';
                };
                user = mkOption {
                  type = types.str;
                  default = "";
                  description = ''
                    If specified, use this remote user to fetch from rsync.
                  '';
                };
                # For upstreams like MX-Linux
                passwordFile = mkOption {
                  type = types.str;
                  default = "";
                  # FIXME: which script(s)?
                  description = ''
                    If specified, the file containing a password for rsync scripts.
                    Note that not all distro types use this.
                    It's mainly intended to be used by our MX-Linux mirror.
                  '';
                };
              };
            };
          };
        };
      }));
    };
  };

  # What needs to be handled for each distribution:
  # Debian:
  #   - ftpsync
  #   - (optionally) ISO images (how?)
  # Ubuntu, mint:
  #   - Releases
  #   - Packages
  #   - (optionally) ISO images (how?)
  # Archlinux, manjaro, mxlinux:
  #   - Packages
  #   - (optionally) ISO images (how?)
  config = mkIf cfg.enable (
    mkMerge (concatMap (
        name: let
          conf = cfg.distros.${name};
        in
          [
            (mkSystemdDistroConfig {
              inherit name;
              variant = "packages";
            })
          ]
          ++ (optional (conf.iso-images.enable) (mkSystemdDistroConfig {
            inherit name;
            variant = "iso";
          }))
          ++ (optional (conf.type == "ubuntu") (mkSystemdDistroConfig {
            inherit name;
            variant = "releases";
          }))
          ++ (optional conf.configureNginx (mkNginxDistroConfig name))
      )
      (attrNames cfg.distros))
  );

  # TODO: delete when all of the frequencies are copied over to the config
  /*
  mkIf cfg.enable (mkMerge [
    (ifDistroEnabled "debian" (cfg: {
      assertions = [
        {
          assertion = (cfg.configuration == null) != (cfg.configurationFile == null);
          message = ''
            Either the option "configuration" or "configurationFile" must be
            specified for "cedille.services.mirrors.distros.debian"
          '';
        }
      ];

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
            else pkgs.writeTextDir "ftpsync.conf" (lib.generators.toKeyValue {} cfg.configuration);
          ftpsync = pkgs.ftpsync.override {
            # Must be a path to the folder containing an ftpsync.conf
            ftpsync-conf = toString config;
            ftpsync-dir = cfg.stateDirectory;
          };
        in "${ftpsync}/bin/ftpsync sync:all";
        serviceConfig =
          serviceConfig'
          //
          # TODO: add this for other mirrors
          {
            AssertPathIsDirectory = cfg.mirrorDirectory;
            AssertPathIsReadWrite = cfg.mirrorDirectory;
            ReadWritePaths = [cfg.mirrorDirectory];
            RequiresMountsFor = cfg.mirrorDirectory;
          };
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
  */
}
