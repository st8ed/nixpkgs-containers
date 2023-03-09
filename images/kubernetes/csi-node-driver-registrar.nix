{ lib, go, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "csi-node-driver-registrar";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "node-driver-registrar";
    rev = "v${version}";
    sha256 = "sha256-Q+uGy+0ZmL0x71KwxRB46YfgHnUr1uNAScbnmku048s=";
  };

  # Package comes with "vendor" directory
  vendorHash = null;
  CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=v${version}"
  ];

  subPackages = [
    "cmd/${pname}"

    # release-tools/filter-junit.go contains unnecessary package
  ];
}
