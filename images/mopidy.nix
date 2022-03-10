{ nixos, mopidy, mopidy-musicbox-webclient, mopidy-mpd, dockerLib }:
let
  mpdPort = "6600";
  httpPort = "6680";

in
dockerLib.buildFromNixos rec {
  name = "mopidy";

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
        port = ${mpdPort}
        zeroconf =
 
        [audio]
        output = pulsesink 
        mixer = software
 
        [logging]
        #verbosity = 4
 
        [http]
        enabled = true
        hostname = 0.0.0.0
        port = ${httpPort}
        allowed_origins =
        default_app = musicbox_webclient
        zeroconf =
 
        [file]
        enabled = true
      '';
    };
  };

  entryService = "mopidy";

  extraConfig = {
    ExposedPorts = {
      "${mpdPort}/tcp" = { };
      "${httpPort}/tcp" = { };
    };
    Volumes = {
      "${system.config.services.mopidy.dataDir}" = { };
    };
  };
}
