{ package, lib, coreutils, gettext, stdenv, makeWrapper, gitea, fetchurl }:

let
  version = "1.16.5";
  sha256 = "sha256-2aqy6DV8oaIur/syg1bk41Wo+FGk3m+05+tUyoDwGHs=";
in
stdenv.mkDerivation {
  pname = "gitea-docker-entrypoint";
  inherit version;

  src = fetchurl {
    url = "https://github.com/go-gitea/gitea/releases/download/v${version}/gitea-src-${version}.tar.gz";
    inherit sha256;
  };

  sourceRoot = "source";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ package ];

  unpackPhase = ''
    mkdir source/
    tar xvf $src -C source/
  '';

  phases = "unpackPhase installPhase";

  installPhase = ''
    cp -R ./docker/rootless $out
      
    mkdir -p $out/app/gitea
    ln -sf ${package}/bin/gitea $out/app/gitea/gitea
      
    chmod +x $out/usr/local/bin/*
      
    patchShebangs $out
    wrapProgram $out/usr/local/bin/docker-setup.sh \
      --prefix PATH : "/usr/local/bin:${lib.makeBinPath [ coreutils gettext ]}"
        
    ln -sf ${package}/bin/environment-to-ini $out/usr/local/bin/environment-to-ini
  '';
}
