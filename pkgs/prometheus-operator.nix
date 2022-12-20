{ lib, go, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "prometheus-operator";
  version = "0.61.1";

  src = fetchFromGitHub {
    owner = "prometheus-operator";
    repo = "prometheus-operator";
    rev = "v${version}";
    sha256 = "sha256-5KyNXSzOcCJQW28lJdDl6ydzDCBqHYBWwtxssJIPUlA=";
  };

  vendorSha256 = "sha256-fCdNM8YdqSvaDi+mwjwk7zS/Dbc/mCmv4SM7AeXP27Q=";

  CGO_ENABLED = "0";

  ldflags =
    let
      t = "github.com/prometheus/common";
    in
    [
      "-s"
      "-X ${t}.Revision=unknown"
      "-X ${t}.Branch=unknown"
      "-X ${t}.BuildUser=nix@nixpkgs"
      "-X ${t}.BuildDate=unknown"
      "-X ${t}.Version=${version}"
      "-X ${t}.GoVersion=${lib.getVersion go}"
    ];

  subPackages = [
    "cmd/operator"
    "cmd/prometheus-config-reloader"
    "cmd/admission-webhook"
  ];
}
