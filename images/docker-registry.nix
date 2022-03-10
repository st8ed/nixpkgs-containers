{ pkgs, lib, nixos, bash, coreutils, dockerLib, enableProxy ? false }:

dockerLib.buildFromNixos rec {
  name = "docker-registry";

  system = nixos {
    services.dockerRegistry = {
      enable = true;
      listenAddress = "0.0.0.0";
      port = 5000;
      storagePath = "/var/lib/docker-registry";

      extraConfig = lib.mkIf enableProxy {
        proxy.remoteurl = "https://registry-1.docker.io";
      };
    };

    users.users.docker-registry.uid = 1000;
    users.groups.docker-registry.gid = 1000;
  };

  entryService = "docker-registry";

  extraConfig = {
    ExposedPorts = {
      "${toString system.config.services.dockerRegistry.port}/tcp" = { };
    };
    Volumes = {
      "${system.config.services.dockerRegistry.storagePath}" = { };
    };
  };

  extraPaths = [ bash coreutils ];
}
