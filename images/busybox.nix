{ dockerTools, pkgsStatic }:

dockerTools.build {
  name = "busybox";
  tag = pkgsStatic.busybox.version;

  extraCommands = ''
    cp -r ${pkgsStatic.busybox}/* .
  '';

  config = {
    Entrypoint = [ "/bin/sh" ];
    User = "0:0";
  };
}
