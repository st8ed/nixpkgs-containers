{ pkgsStatic, lib, dockerTools, cni-plugin-flannel }:

dockerTools.build {
  name = "flannel-cni-plugin";
  tag = "v${cni-plugin-flannel.version}";

  extraCommands = ''
    cp ${cni-plugin-flannel}/bin/flannel ./flannel

    # Necessary for 'cp' command used
    # by official Kubernetes distribution via manifest
    mkdir -p ./bin
    cp ${pkgsStatic.busybox}/bin/* ./bin/
  '';

  config = {
    WorkingDir = "/";
    Env = [
      "PATH=/bin"
    ];
  };

  meta = with lib; {
    description = "Flannel (cni plugin package)";
    replacementImage = "docker.io/flannel/flannel-cni-plugin";
    replacementImageUrl = "https://github.com/flannel-io/cni-plugin/blob/3e8006e5acf061257b53423d4c8d9ff54a8c965b/Dockerfile.amd64";

    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
