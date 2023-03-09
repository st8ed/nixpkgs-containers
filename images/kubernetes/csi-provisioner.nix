{ lib, go, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "csi-provisioner";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-provisioner";
    rev = "v${version}";
    sha256 = "sha256-xuDUag67Dfat8uwQujGU0cQuNS0nOrQgARiXa9UToHY=";
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
