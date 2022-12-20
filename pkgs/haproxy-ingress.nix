{ buildGoModule, haproxy, fetchFromGitHub, stdenv }:

let
  version = "0.13.9";

  src = fetchFromGitHub {
    owner = "jcmoraisjr";
    repo = "haproxy-ingress";
    rev = "v${version}";
    hash = "sha256-OnIs9mQ7AaP2UI+PKCzDYZLHesUnjukvy8W8q/SLznc=";
  };

  vendorSha256 = "sha256-ebOIp14y3fVrU8O5mhkEFntoTV20r1casNiKKWmsMVI=";

  json4lua = stdenv.mkDerivation {
    pname = "json4lua";
    version = "1.0.0";

    src = fetchFromGitHub {
      owner = "craigmj";
      repo = "json4lua";
      rev = "40fb13b0ec4a70e36f88812848511c5867bed857";
      sha256 = "sha256-RPibcBzprWrNtt/MrwXxx77rd70btXGqDywnvf0yHZw=";
    };

    phases = "unpackPhase installPhase";

    installPhase = ''
      mkdir -p $out/share/lua/5.3
      cp json/json.lua $out/share/lua/5.3/
    '';
  };

in
buildGoModule rec {
  pname = "haproxy-ingress";

  inherit version src vendorSha256;

  buildPhase = ''
    runHook preBuild
    # patchShebangs .
    make GIT_REPO=https://github.com/jcmoraisjr/haproxy-ingress GIT_COMMIT=${src.rev}
    runHook postBuild
  '';

  # doTests = false;

  installPhase = ''
    mkdir -p $out
      
    # TODO: Move to passthrough packages?
    cp -r rootfs/* $out/
    chmod +x $out/*.sh
      
    # TODO: Proper Lua dependencies?
    cp -r ${json4lua}/* $out/
  '';
}
