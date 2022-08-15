{ lib, dockerTools, prometheus-operator }:

dockerTools.build {
  name = "prometheus-operator";
  tag = prometheus-operator.version;

  contents = [ prometheus-operator ];
  config = {
    Entrypoint = [ "/bin/operator" ];
    Cmd = [ ];
    User = "65534:65534";
  };

  meta = with lib; {
    description = "Prometheus operator";
    replacementImage = "quay.io/prometheus-operator/prometheus-operator";
    replacementImageUrl = "https://github.com/prometheus-operator/prometheus-operator/blob/main/Dockerfile";

    license = licenses.asl20;
    platform = platforms.linux;
  };
}
