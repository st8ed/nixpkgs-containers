{ pkgs, lua, buildGoModule, luaPackages, haproxy, fetchFromGitHub, stdenv }:

let
  json4lua = with luaPackages; buildLuarocksPackage rec {
    pname = "json4lua";
    version = "1.0.0-1";

    src = fetchFromGitHub {
      owner = "craigmj";
      repo = "json4lua";
      rev = "37b09f750f062fcf7a3a2e0d4e0f378fdaf665c6";
      sha256 = "sha256-0BjiR6cAQhQf6JyccoCYnhX9/ZSobzn31rnT52w1Td4=";
    };

    preConfigure = ''
      sed -i 's/version="1\.0\.0"/version="1.0.0-1"/' *-1.0.0-1.rockspec
      sed -i '/"luasocket"/d' *-1.0.0-1.rockspec
    '';

    disabled = with lua; luaOlder "5.2";

    propagatedBuildInputs = [
      # Do not propagate it as this functionality is not essential for haproxy
      # luasocket
    ];
  };

in
buildGoModule rec {
  pname = "haproxy-ingress";
  version = "0.14.2";

  src = fetchFromGitHub {
    owner = "jcmoraisjr";
    repo = "haproxy-ingress";
    rev = "v${version}";
    hash = "sha256-e7U/WeARc/G+5ZFoZgwC4Izk+yxUNIuakSaExWQoLOo=";
  };

  vendorSha256 = "sha256-JqaX1CUsdLo9t3hW8+/lpDnevfjwjIVg7NJjM26mXdA=";

  outputs = [ "out" "rootfs" ];

  propagatedBuildInputs = [
    luaPackages.wrapLua
    json4lua
  ];

  CGO_ENABLED = "0";

  ldflags =
    let
      t = "github.com/jcmoraisjr/haproxy-ingress/pkg/version";
    in
    [
      "-s"
      "-w"
      "-X ${t}.RELEASE=local"
      "-X ${t}.COMMIT=${src.rev}"
      "-X ${t}.REPO=${src.url}"
    ];

  subPackages = [
    "pkg"
  ];

  postFixup = ''
    wrapLuaPrograms
  '';

  postInstall = ''
    mv $out/bin/pkg $out/bin/haproxy-ingress-controller

    mkdir -p $rootfs
    ln -s $out/bin/haproxy-ingress-controller $rootfs/haproxy-ingress-controller

    cp -r $src/rootfs/. $rootfs/
    chmod +x $rootfs/*.sh
  '';
}
