{ dockerTools, prometheus }:

dockerTools.buildWithUsers rec {
  name = "prometheus";
  tag = prometheus.version;

  contents = [ prometheus ]; 

  users = {
    users.prometheus = {
      uid = 255;
      name = "prometheus";
      group = "prometheus";
      home = "/home/prometheus";
    };
    groups.prometheus = {
      gid = 255;
      name = "prometheus";
      members = [ "prometheus" ];
    };
  };

  fakeRootCommands = ''
    install -dm777 ./var/lib/prometheus2
  '';

  config = {
    Entrypoint = [ "/bin/prometheus" ];
    Cmd = [ ];
    User = "prometheus:prometheus";

    ExposedPorts = {
      "9090/tcp" = { };
    };
    Volumes = {
      "/var/lib/prometheus2" = { };
    };
  };
}
