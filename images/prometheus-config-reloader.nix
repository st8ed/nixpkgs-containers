{ dockerTools, prometheus-operator }:

dockerTools.build {
  name = "prometheus-config-reloader";
  tag = prometheus-operator.version;

  contents = [ prometheus-operator ];
  config = {
    Entrypoint = [ "/bin/prometheus-config-reloader" ];
    Cmd = [ ];
    User = "65534:65534";
  };
}

