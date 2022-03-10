{ pkgs, nixos, dockerLib }:

dockerLib.buildFromNixos rec {
  name = "minio";

  system = nixos {
    services.minio = {
      enable = true;
      listenAddress = "0.0.0.0:9000";
      consoleAddress = "0.0.0.0:9001";
      configDir = "/var/lib/minio/config";
      dataDir = [ "/var/lib/minio/data" ];
    };

    users.users.minio = {
      home = "/var/lib/minio";
    };
  };

  entryService = "minio";

  extraConfig = {
    ExposedPorts = {
      "9000/tcp" = { };
      "9001/tcp" = { };
    };
    Volumes = {
      "${system.config.users.users.minio.home}" = { };
    };
  };
}
