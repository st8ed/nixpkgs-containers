{ pkgs, lib, dockerTools, go, buildGoModule }:

let
  package =
    buildGoModule rec {
      pname = "kube-state-metrics";
      version = "2.7.0";

      src = pkgs.fetchFromGitHub {
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

      # "Failed to run kube-state-metrics" err="failed to create client: stat /homeless-shelter/.kube/config: no such file or directory"
      doCheck = false;
    };

in
dockerTools.build rec {
  name = "kube-state-metrics";
  tag = "v${package.version}";

  contents = package;

  config = {
    Entrypoint = [
      "/bin/kube-state-metrics"
      "--port=8080"
      "--telemetry-port=8081"
    ];
    Cmd = [ ];
    User = "65534:65534";
    Env = [ ];
    ExposedPorts = {
      "8080/tcp" = { };
      "8081/tcp" = { };
    };
  };

  meta = with lib; {
    description = "Generate metrics about Kubernetes objects";
    replacementImage = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
    replacementImageUrl = "https://github.com/kubernetes/kube-state-metrics/blob/master/Dockerfile";

    license = licenses.asl20;
    platform = platforms.linux;
  };
}
