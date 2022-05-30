{ dockerTools, prometheus-alertmanager }:

dockerTools.build rec {
  name = "prometheus-alertmanager";
  tag = prometheus-alertmanager.version;

  contents = [
    prometheus-alertmanager
  ];

  fakeRootCommands = ''
    install -dm770 -o 255 -g 255 ./etc/alertmanager
    install -dm770 -o 255 -g 255 ./var/lib/alertmanager
  '';

  config = {
    Entrypoint = [ "/bin/alertmanager" ];
    Cmd = [
      "--config.file=/etc/alertmanager/alertmanager.yml"
      "--storage.path=/var/lib/alertmanager"
    ];
    User = "255:255";
    WorkingDir = "/var/lib/alertmanager";

    Volumes = {
      "/var/lib/alertmanager" = { };
    };
    ExposedPorts = {
      "9093/tcp" = { };
    };
  };
}
