{ lib, dockerTools, nixos, minio }:

let
  listenPort = 9000;
  consolePort = 9001;

  system = nixos {
    services.minio = {
      enable = true;
      listenAddress = "0.0.0.0:${toString listenPort}";
      consoleAddress = "0.0.0.0:${toString consolePort}";
      configDir = "/var/lib/minio/config";
      dataDir = [ "/var/lib/minio/data" ];
    };

    users.users.minio = {
      home = "/var/lib/minio";
    };
  };

in
dockerTools.buildFromNixos rec {
  name = "minio";
  tag = minio.version;

  inherit system;
  entryService = "minio";

  extraConfig = {
    ExposedPorts = {
      "${toString listenPort}/tcp" = { };
      "${toString consolePort}/tcp" = { };
    };
    Volumes = {
      "${system.config.users.users.minio.home}" = { };
    };
  };

  meta = with lib; {
    description = "MinIO server";

    license = licenses.agpl3;
    platform = platforms.x86_64;
  };
}
