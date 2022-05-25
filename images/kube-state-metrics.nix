{ kube-state-metrics, dockerTools, pkgs, lib }:

let
  package = kube-state-metrics;

in
dockerTools.build rec {
  name = "kube-state-metrics";
  tag = package.version;

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
}
