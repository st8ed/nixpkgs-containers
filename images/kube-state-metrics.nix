{ pkgs, lib, dockerTools, kube-state-metrics }:

let
  package = kube-state-metrics;

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
