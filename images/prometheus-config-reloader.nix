{ lib, dockerTools, prometheus-operator }:

dockerTools.build {
  name = "prometheus-config-reloader";
  tag = prometheus-operator.version;

  contents = [ prometheus-operator ];
  config = {
    Entrypoint = [ "/bin/prometheus-config-reloader" ];
    Cmd = [ ];
    User = "65534:65534";
  };

  meta = with lib; {
    description = "Prometheus config reload helper";
    replacementImage = "quay.io/prometheus-operator/prometheus-config-reloader";
    replacementImageUrl = "https://github.com/prometheus-operator/prometheus-operator/blob/main/cmd/prometheus-config-reloader/Dockerfile";

    license = licenses.asl20;
    platform = platforms.linux;
  };
}

