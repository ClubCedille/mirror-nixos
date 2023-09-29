{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  rsync,
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

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p "$out/share" "$out/bin"

    cp -rv "$src/img" "$src/index.html" "$src/index_en.html" "$out/share"
    install -v "$shellScripts"/*.sh "$out/bin"
  '';

  preFixup = ''
    for script in "$out/bin/"*.sh; do
      # Let the scripts have `rsync` and themselves in their PATH
      wrapProgram "$script" --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath [rsync (builtins.placeholder "out")])}
    done
  '';
}
