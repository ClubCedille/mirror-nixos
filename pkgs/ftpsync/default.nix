{
  stdenvNoCC,
  lib,
  fetchFromGitLab,
  makeWrapper,
  substituteAll,
  # Dependencies used by the shell scripts
  coreutils,
  gawk,
  gnugrep,
  gnused,
  openssh,
  rsync,
  socat,
  stunnel,
  system-sendmail,
  # TODO: find a cleaner way to pass these
  ftpsync-conf ? "/etc/ftpsync",
  ftpsync-dir ? "/var/lib/ftpsync",
}:
stdenvNoCC.mkDerivation rec {
  pname = "ftpsync";
  version = "20180513";

  src = fetchFromGitLab {
    domain = "salsa.debian.org";
    owner = "mirror-team";
    repo = "archvsync";
    rev = "${version}";
    sha256 = "sha256-P224HQ5MfWAEvndXuDygVhZyGczgByhmfnL9CHYnc6Y=";
  };

  nativeBuildInputs = [makeWrapper];

  # There is no configure script
  dontConfigure = true;

  # It's not going to be in the cache anyway if custom ftpsync-dir or conf are given.
  preferLocalBuild = true;
  allowSubstitutes = false;

  patches = [
    (substituteAll {
      src = ./ftpsync-fix-hardcoded-paths-and-config-paths.patch;

      # Can't use dashes in names here because they need to be valid Bash names
      ftpsync_conf = ftpsync-conf;
      ftpsync_dir = ftpsync-dir;
    })
  ];

  # Ignore the Makefile in the project, because it assumes git is callable
  # and it also assumes the installation directory is `/usr/bin`, without any easy way to override it.
  # This `sed` incantation is taken almost verbatim from the Makefile.
  buildPhase = ''
    sed -i -r \
           -e '/## INCLUDE COMMON$$/ {' \
           -e 'r bin/common' \
           -e 'r bin/include-install' \
           -e 'c VERSION="${version}"' \
           -e '};' \
           bin/ftpsync
  '';

  installPhase = ''
    mkdir -p "$out/bin" "$out/etc"

    # Defaults to rwxr-xr-x
    install -v bin/ftpsync bin/rsync-ssl-tunnel "$out/bin/"
    cp -v etc/ftpsync.conf.sample "$out/etc/"
  '';

  preFixup = ''
    wrapProgram "$out/bin/ftpsync" --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath [
      coreutils
      gawk
      gnugrep
      gnused
      openssh
      rsync
      system-sendmail
    ])}
    wrapProgram "$out/bin/rsync-ssl-tunnel" --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath [
      coreutils
      openssh
      rsync
      socat # an alternative rsync SSL method (is it really needed?)
      stunnel # Used as rsync's default SSL method
    ])}
  '';

  meta = {
    homepage = "https://packages.debian.org/stable/ftpsync";
  };
}
