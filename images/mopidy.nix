{ lib, dockerTools, nixos, mopidy, mopidy-musicbox-webclient, mopidy-mpd }:
let
  mpdPort = 6600;
  httpPort = 6680;

  system = nixos {
    config.services.mopidy = {
      enable = true;

      extensionPackages = [
        mopidy-musicbox-webclient
        mopidy-mpd
      ];

      dataDir = "/var/lib/mopidy";

      configuration = ''
        [core]
        restore_state = true
          
        [mpd]
        enabled = true
        hostname = 0.0.0.0
        port = ${toString mpdPort}
        zeroconf =
  
        [audio]
        output = pulsesink 
        mixer = software
  
        [logging]
        #verbosity = 4
  
        [http]
        enabled = true
        hostname = 0.0.0.0
        port = ${toString httpPort}
        allowed_origins =
        default_app = musicbox_webclient
        zeroconf =
  
        [file]
        enabled = true
      '';
    };
  };

in
dockerTools.buildFromNixos {
  name = "mopidy";

  inherit system;
  entryService = "mopidy";

  extraConfig = {
    ExposedPorts = {
      "${toString mpdPort}/tcp" = { };
      "${toString httpPort}/tcp" = { };
    };
    Volumes = {
      "${system.config.services.mopidy.dataDir}" = { };
    };
  };

  meta = with lib; {
    description = "Mopidy media server";

    license = licenses.asl2;
    platform = platforms.linux;
  };
}
