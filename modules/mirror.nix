{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) attrNames concatMap elem filter isString listToAttrs mkEnableOption mkIf mkMerge mkOption optional toUpper types;
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
      distroCfg = cfg.distros.${name};
      distroType = distroCfg.type;
      # Attrs of common INFO_* about this mirror
      info-env-vars =
        # Names from the `ftpsync` script (and from the info part of the distro config)
        listToAttrs (filter (env-pair: env-pair.value != "")
          (map (n: {
              name = "INFO_" + (toUpper n);
              value = cfg.info.${n};
            }) [
              "maintainer"
              "sponsor"
              "country"
              "location"
              "throughput"
            ]));
    in
      if distroType == "debian"
      then
        if variant == "packages"
        then {
          environment =
            info-env-vars
            // {
              RSYNC_HOST = distroCfg.upstream.domain;
              RSYNC_TRANSPORT = distroCfg.upstream.transport;
              TO = distroCfg.mirrorDirectory;
              RSYNC_PATH = distroCfg.upstream.path;
            };
          script = ''
            exec '${pkgs.ftpsync}/bin/ftpsync' sync:all
          '';
        }
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
        serviceConfig = let
          mirrorDirectory = cfg.distros.${name}.mirrorDirectory;
        in
          serviceConfig'
          // (mkDistroScript {inherit name variant;})
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
      distroCfg = cfg.distros.${name};
      value = assert !(lib.hasInfix "/" name); {
        locations."/${name}/".root = distroCfg.mirrorDirectory;
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

    # TODO: an option for the name of the mirror host

    info = mkOption {
      description = ''
        Optional information about the host that will be shown for some mirror types, like `debian`.
      '';
      type = types.submodule {
        options = {
          maintainer = mkOption {
            type = types.str;
            default = "";
            description = ''
              Who maintains this mirror? This is useful to let users know who to thank for maintaining this mirror.
            '';
          };

          sponsor = mkOption {
            type = types.str;
            default = "";
            description = ''
              Sponsors usually want others to know they sponsor you.
              Name them here to include them along with the rest of the informations about this mirror.
            '';
          };

          country = mkOption {
            type = types.str;
            default = "";
            description = ''
              Users usually want the closest mirror to them, so knowing the country in which the servers hosting your mirror are located is very helpful.
            '';
          };

          location = mkOption {
            type = types.str;
            default = "";
            description = ''
              This is a more specific location than the country. For example, if your mirror is hosted in a university, you might want to put the name of the university in here.
            '';
          };

          throughput = mkOption {
            type = types.str;
            default = "";
            # TODO: which format for the bandwidth?
            description = ''
              The network bandwidth your mirror is capable of serving.
            '';
          };
        };
      };
    };

    distros = mkOption {
      type = types.attrsOf (types.submodule ({
        config,
        name,
      }: let
        distroCfg = cfg.distros.${name};
      in {
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

          # NOTE: previously, when this module was first written, it used fixed times of the day.
          # debian:          00:17, 04:17, 08:17, 12:17, 16:17 and 20:17 every day
          # mint:            00:20 and 12:20 every day
          # mint-releases:   22:02 every day
          # ubuntu:          00:51, 06:51, 12:51 and 18:51 every day
          # ubuntu-releases: 03:51 every day
          # archlinux:       00:36, 02:36, 04:36, 06:36, 10:36, 12:36, 14:36, 16:36, 18:36, 20:36 and 22:36 every day
          # manjaro:         00:43, 04:43, 08:43, 12:43, 16:43 and 20:43 every day
          # mx-linux:        00:30 and 12:30 every day
          # FIXME: different frequency for releases
          frequency = mkOption {
            type = types.str;
            example = "3h 45min";
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
          # TODO: add include/exclude sub-options
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
                transport = mkOption {
                  # TODO: are there other possible transports?
                  type = types.nullOr (types.enum ["ssh" "ssl"]);
                  default = null;
                  description = lib.mdDoc "The transport used by `rsync`";
                };
                domain = mkOption {
                  type = types.str;
                  description = ''
                    The domain name of the upstream rsync source that will be mirrored.
                  '';
                };
                path = mkOption {
                  type = types.str;
                  default =
                    if distroCfg.type == "debian"
                    then "debian"
                    else "";
                  # TODO: Add examples! (can this end with "/"?)
                  description = ''
                    The remote path mirrored with rsync
                  '';
                };
                # FIXME: use this at the right places including when actually using:
                # - rsync over SSL
                # - rsync over SSH
                # - Other transport?? (plain rsync?)
                port = mkOption {
                  type = types.nullOr types.port;
                  default =
                    if distroCfg.upstream.transport == "ssh"
                    then 22
                    else if distroCfg.upstream.transport == "ssl"
                    then 1873
                    else null;
                  description = ''
                    The remote rsync port, using the transport protocol specified elsewhere.
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
                  # FIXME: which script(s) are/will be using this?
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
}
