{ lib, go, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "csi-snapshotter";
  version = "4.0.0";

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-snapshotter";
    rev = "v${version}";
    sha256 = "sha256-HPvQL/j1d7zhJ2klYJoYPG2MEdD9+4LfhPNrDHdC2Lo=";
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
    "cmd/snapshot-controller"
    "cmd/snapshot-validation-webhook"

    # release-tools/filter-junit.go contains unnecessary package
  ];
}
