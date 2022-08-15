{ lib, dockerTools, pkgsStatic }:

let
  socat = pkgsStatic.socat;

in
dockerTools.build {
  name = "socat";
  tag = socat.version;

  extraCommands = ''
    cp -r ${socat}/* .
  '';

  config = {
    Entrypoint = [ "/bin/socat" ];
    User = "1000:1000";
  };

  meta = with lib; {
    description = "Static build of socat";

    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
