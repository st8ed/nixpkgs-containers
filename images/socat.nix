{ pkgsStatic, lib, dockerTools }:

dockerTools.build {
  name = "socat";
  tag = pkgsStatic.socat.version;

  extraCommands = ''
    cp -r ${pkgsStatic.socat}/* .
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
