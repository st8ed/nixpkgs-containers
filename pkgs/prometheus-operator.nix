{ lib, go_1_17, buildGo117Module, fetchFromGitHub }:

buildGo117Module rec {
  pname = "prometheus-operator";
  version = "0.56.2";

  src = fetchFromGitHub {
    owner = "prometheus-operator";
    repo = "prometheus-operator";
    rev = "86b60f698c95dd9b5c060ce81b29c4252a46110d"; #rev = "v${version}";
    sha256 = "sha256-g4xJVOs4lcZjVZfczgn5ulbhshH/Wiv+4eFttS8bIUU=";
  };

  vendorSha256 = "sha256-UhKWzaWkiqBuG5p6k9OidNbFalYk0IxxjGoca8J2A74=";

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
      "-X ${t}.GoVersion=${lib.getVersion go_1_17}"
    ];

  subPackages = [
    "cmd/operator"
    "cmd/prometheus-config-reloader"
    "cmd/admission-webhook"
  ];
}
