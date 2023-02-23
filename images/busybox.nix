{ pkgsStatic, lib, dockerTools }:

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

  meta = with lib; {
    description = "Static build of busybox";
    replacementImage = "docker.io/library/busybox";
    replacementImageUrl = "https://hub.docker.com/_/busybox";

    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
