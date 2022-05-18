{ buildGoModule, haproxy, fetchFromGitHub, stdenv }:

let
  version = "0.13.7";

  src = fetchFromGitHub {
    owner = "jcmoraisjr";
    repo = "haproxy-ingress";
    rev = "346c94fc1601b07c9793134231c2be2ed36025c6";
    sha256 = "sha256-maFDMgBsMS7Mt1a1CiVROg6xcemP0+/cxFe5J9sGDAQ=";
  };

  vendorSha256 = "sha256-S3jNa/zgwGa1YEgymPqgydTDQjAve2b2vxAyn0LhWjM=";

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
