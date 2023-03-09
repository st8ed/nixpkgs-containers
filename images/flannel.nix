{ pkgsStatic, lib, dockerTools, flannel, iptables, iproute, nettools }:

# TODO: Add strongswan, wireguard-tools dependencies

dockerTools.build {
  name = "flannel";
  tag = "v${flannel.version}";

  extraCommands = ''
    mkdir -p ./opt/bin
    ln -sf ${flannel}/bin/flannel ./opt/bin/flanneld

    # Necessary for 'cp' command used
    # by official Kubernetes distribution via manifest
    mkdir -p ./bin
    cp ${pkgsStatic.busybox}/bin/* ./bin/
  '';

  config = {
    Entrypoint = [ "/opt/bin/flanneld" ];
    WorkingDir = "/";
    Env = [
      "PATH=${lib.makeBinPath ([
        "/"
        iptables
        iproute
        nettools
      ])}"
    ];
  };

  meta = with lib; {
    description = "Flannel";
    replacementImage = "docker.io/flannel/flannel";
    replacementImageUrl = "https://github.com/flannel-io/flannel/blob/8124fc7978e9789efbdc6766580aec6575a9c6ce/images/Dockerfile.amd64";
    # See also: https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
