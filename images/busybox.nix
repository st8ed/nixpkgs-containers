{ lib, dockerTools, pkgsStatic }:

let
  busybox = pkgsStatic.busybox;

in
dockerTools.build {
  name = "busybox";
  tag = busybox.version;

  extraCommands = ''
    cp -r ${busybox}/* .
  '';

  config = {
    Entrypoint = [ "/bin/sh" ];
    User = "0:0";
  };

  meta = with lib; {
    description = "Static build of busybox";
    replacementImage = "library/busybox";
    replacementImageUrl = "https://hub.docker.com/_/busybox";

    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
