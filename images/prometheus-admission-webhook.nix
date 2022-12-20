{ lib, dockerTools, prometheus-operator }:

dockerTools.build {
  name = "prometheus-admission-webhook";
  tag = "v${prometheus-operator.version}";

  contents = [ prometheus-operator ];
  config = {
    Entrypoint = [ "/bin/admission-webhook" ];
    Cmd = [ ];
    User = "65534:65534";
  };

  meta = with lib; {
    description = "Prometheus webhook helper";
    replacementImage = "quay.io/prometheus-operator/admission-webhook";
    replacementImageUrl = "https://github.com/prometheus-operator/prometheus-operator/blob/main/cmd/admission-webhook/Dockerfile";

    license = licenses.asl20;
    platform = platforms.linux;
  };
}

