{ lib, go_1_17, buildGo117Module, fetchFromGitHub }:

buildGo117Module rec {
  pname = "kube-state-metrics";
  version = "2.4.2";

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kube-state-metrics";
    rev = "v${version}";
    sha256 = "sha256-Yui+m1jY4wnmJyK4VDEA/OLu2EZ3kWdcUyS/FHRQpm4=";
  };

  vendorSha256 = "sha256-0N4W/TG9xxme7zLXUMqdexTadar3Ceml3mRBik4MsAE=";

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
      "-X ${t}/version.GoVersion=${lib.getVersion go_1_17}"
    ];

  doCheck = false;
}
