{ lib, dockerTools, kubernetes, iptables, iproute, conntrack-tools }:

let
  version = kubernetes.version;

in
{
  pause = dockerTools.build {
    name = "pause";
    tag = kubernetes.pause.version;

    extraCommands = ''
      cp ${kubernetes.pause}/bin/pause ./pause
    '';

    config = {
      Entrypoint = [ "/pause" ];
      User = "65535:65535";
    };

    meta = with lib; {
      description = "Pod infra image (sandbox image) for Kubernetes";
      replacementImage = "registry.k8s.io/pause";
      replacementImageUrl = "https://github.com/kubernetes/kubernetes/blob/5437d493da9435c9a32b244cd8bb12faf88075ae/build/pause/Dockerfile";

      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };
}

  // (lib.genAttrs [
  "kube-apiserver"
  "kube-controller-manager"
  "kube-scheduler"
  "kube-proxy"
]
  (binary: dockerTools.build {
    name = binary;
    tag = "v${version}";

    extraCommands = ''
      mkdir -p ./usr/local/bin
      cp ${kubernetes}/bin/${binary} ./usr/local/bin/${binary}
    '';

    config = {
      Entrypoint = [ ];
      WorkingDir = "/";
      Env = [
        "PATH=${lib.makeBinPath ([
      "/" "/usr/local"
    ] ++ (lib.optionals (binary == "kube-proxy") [
      iptables
      iproute
      conntrack-tools
    ]))}"
      ];
    };

    meta = with lib; {
      description = "Kubernetes binary package";
      replacementImage = "registry.k8s.io/${binary}";
      replacementImageUrl = "https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile";

      license = licenses.asl20;
      platforms = platforms.linux;
    };
  }))
