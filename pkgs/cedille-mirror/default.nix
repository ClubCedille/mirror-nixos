{ stdenv
, lib
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "cedille-mirror";
  version = "1.0.0";

  # nix-prefetch-url https://github.com/clubcedille/miroirs/archive/$REV.tar.gz
  src = fetchFromGitHub {
    owner = "clubcedille";
    repo = "mirrors";
    rev = "";
    sha256 = lib.fakeSha256;
  };

  dontBuild = true;
  dontConfigure = true;
  dontPatch = true;
  dontFixup = true;

  buildInputs = [

  ];

  installPhase = ''
    mkdir -p "$out/share/" "$out/bin"
    cp -r "$src/img" "$src/index.html" "$src/index_en.html" "$out/share"
    cp -r "$src/scripts" "$out/bin"
  '';
}
