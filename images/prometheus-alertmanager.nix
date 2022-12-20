{ pkgs, lib, dockerTools, prometheus-alertmanager }:

dockerTools.build rec {
  name = "prometheus-alertmanager";
  tag = "v${prometheus-alertmanager.version}";

  contents = [
    prometheus-alertmanager
  ];

  fakeRootCommands = ''
    install -dm777 ./var/lib/alertmanager
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

  meta = with lib; {
    description = "Prometheus Alert Manager";
    replacementImage = "prom/alertmanager";
    replacementImageUrl = "https://github.com/prometheus/alertmanager/blob/main/Dockerfile";

    license = licenses.asl20;
    platform = platforms.linux;
  };
}
