{ stdenv
, lib
, fetchFromGitHub
, rsync
}:

stdenv.mkDerivation {
  pname = "cedille-mirror";
  version = "1.0.0";

  # nix-prefetch-url https://github.com/clubcedille/mirrors/archive/$REV.tar.gz
  src = fetchFromGitHub {
    owner = "clubcedille";
    repo = "mirrors";
    rev = "d834b7d61ec6fe115dafda8f0728aecf11649068";
    sha256 = "sha256-HZNcYIApBrh+JLqImi92FAaOIKAzTZC6KN3za1ySDtU=";
  };

  shellScripts = ../scripts;

  dontBuild = true;
  dontConfigure = true;
  dontPatch = true;

  buildInputs = [

  ];

  installPhase = ''
    mkdir -p "$out/share" "$out/bin"

    cp -r "$src/img" "$src/index.html" "$src/index_en.html" "$out/share"
    cp "$shellScripts"/*.sh "$out/bin"

    for script in "$out/bin"/*.sh; do
      chmod +x "$script"
      substituteInPlace "$script" \
        --subst-var-by base_path "$out/bin" \
        --subst-var-by rsync "${rsync}";
    done
  '';
}
