{ dockerTools, prometheus-operator }:

dockerTools.build {
  name = "prometheus-operator";
  tag = prometheus-operator.version;

  contents = [ prometheus-operator ];
  config = {
    Entrypoint = [ "/bin/operator" ];
    Cmd = [ ];
    User = "65534:65534";
  };
}
