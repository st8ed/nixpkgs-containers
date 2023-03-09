{ lib, go, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "csi-resizer";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-resizer";
    rev = "v${version}";
    sha256 = "sha256-QjRDjDSZlW9c4chjqeXxAzTpcMapwb9hSOf4Mw6lYfs=";
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
