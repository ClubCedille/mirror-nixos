{ stdenv
, lib
, fetchFromGitLab
, makeWrapper
, substituteAll
# Dependencies used by the shell scripts
, rsync
, system-sendmail
, openssh
, ftpsync-conf ? "/etc/ftpsync"
, ftpsync-dir ? "/var/lib/ftpsync"
}:

stdenv.mkDerivation rec {
  pname = "ftpsync";
  version = "20180513";

  src = fetchFromGitLab {
    domain = "salsa.debian.org";
    owner = "mirror-team";
    repo = "archvsync";
    rev = "${version}";
    sha256 = "sha256-P224HQ5MfWAEvndXuDygVhZyGczgByhmfnL9CHYnc6Y=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Ignore the Makefile in the project
  dontBuild = true;
  dontConfigure = true;

  patches = [
    (substituteAll {
      src = ./ftpsync-fix-hardcoded-paths-and-config-paths.patch;
      isExecutable = true;

      ftpsync-conf = ftpsync-conf;
      ftpsync-dir = ftpsync-dir;

      sendmail = system-sendmail;
      rsync = rsync;
      ssh = openssh;
    })
  ];

  postPatch = ''
    ls -lA bin
    sed -i -r \
           -e '/## INCLUDE COMMON$$/a {' \
           -e 'r bin/common'
           -e 'r bin/include-install' \
           -e 'c VERSION="${version}"' \
           -e '};' \
           bin/ftpsync
  '';

  installPhase = ''
    mkdir -p "$out/bin" "$out/etc"

    cp -v bin/ftpsync "$out/bin/"
    cp -v etc/ftpsync.conf.sample "$out/etc/"

    substituteAllInPlace "$out/bin/common" \
      --subst-var-by "test" "toto"

    #wrapProgram "$out/bin/common"
  '';

  meta = with lib; {
    homepage = "https://packages.debian.org/stable/ftpsync";

  };
}