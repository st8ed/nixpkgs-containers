{ dockerTools, prometheus-operator }:

dockerTools.build {
  name = "prometheus-admission-webhook";
  tag = prometheus-operator.version;

  contents = [ prometheus-operator ];
  config = {
    Entrypoint = [ "/bin/admission-webhook" ];
    Cmd = [ ];
    User = "65534:65534";
  };
}

