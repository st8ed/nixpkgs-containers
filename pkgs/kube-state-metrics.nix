{ lib, go, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "kube-state-metrics";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kube-state-metrics";
    rev = "v${version}";
    sha256 = "sha256-6uYylGhM8Q/YILqD2wS803ijcuOLyjD0NpCBTOBVe4Y=";
  };

  vendorSha256 = "sha256-fLZdmi5TCUrwuwWPUrVCeqznCL1fQn+MxrV3pJuut6k=";

  CGO_ENABLED = "0";

  ldflags =
    let
      t = "github.com/prometheus/common";
    in
    [
      "-s"
      "-w"
      "-X ${t}/version.Revision=unknown"
      "-X ${t}/version.Branch=unknown"
      "-X ${t}/version.BuildUser=nix@nixpkgs"
      "-X ${t}/version.BuildDate=unknown"
      "-X ${t}/version.Version=${version}"
      "-X ${t}/version.GoVersion=${lib.getVersion go}"
    ];

  doCheck = false;
}
