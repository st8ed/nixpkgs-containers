pkgs: super: {
  haproxy-ingress = pkgs.callPackage ./pkgs/haproxy-ingress.nix { };

  gitea-docker-entrypoint = pkgs.callPackage ./pkgs/gitea-docker-entrypoint.nix {
    gitea = pkgs.gitea.override {
      pamSupport = false;
    };
  };

  kube-state-metrics = pkgs.callPackage ./pkgs/kube-state-metrics.nix { };
  prometheus-operator = pkgs.callPackage ./pkgs/prometheus-operator.nix { };

  dockerImages = pkgs.lib.makeScope super.newScope (self: {
    bind = pkgs.callPackage ./images/bind.nix { };
    busybox = pkgs.callPackage ./images/busybox.nix { };
    code-server = pkgs.callPackage ./images/code-server.nix { };
    docker-registry = pkgs.callPackage ./images/docker-registry.nix { };
    gitea = pkgs.callPackage ./images/gitea.nix { };
    grafana = pkgs.callPackage ./images/grafana.nix { };
    haproxy-ingress = pkgs.callPackage ./images/haproxy-ingress.nix { };
    haproxy = pkgs.callPackage ./images/haproxy.nix { };
    home-assistant = pkgs.callPackage ./images/home-assistant.nix { };
    k8s-sidecar = pkgs.callPackage ./images/k8s-sidecar.nix { };
    kube-state-metrics = pkgs.callPackage ./images/kube-state-metrics.nix { };
    minio = pkgs.callPackage ./images/minio.nix { };
    mopidy = pkgs.callPackage ./images/mopidy.nix { };
    nfs-ganesha = pkgs.callPackage ./images/nfs-ganesha.nix { };
    prometheus-admission-webhook = pkgs.callPackage ./images/prometheus-admission-webhook.nix { };
    prometheus-alertmanager = pkgs.callPackage ./images/prometheus-alertmanager.nix { };
    prometheus-config-reloader = pkgs.callPackage ./images/prometheus-config-reloader.nix { };
    prometheus-operator = pkgs.callPackage ./images/prometheus-operator.nix { };
    prometheus = pkgs.callPackage ./images/prometheus.nix { };
    socat = pkgs.callPackage ./images/socat.nix { };
    transmission = pkgs.callPackage ./images/transmission.nix { };

    README = with pkgs.lib; pkgs.writeText "README.md" ''
      | Image  | Replacement image | Description |
      |---|---|---|
      ${concatMapStringsSep "\n" (v:
      "| ${v.imageName}:${v.imageTag} " +
      "| ${optionalString (v.meta ? replacementImage)
        "[${v.meta.replacementImage}](${v.meta.replacementImageUrl})"
      } " +
      "| ${optionalString (v.meta ? description) v.meta.description} " +
      "|"
      ) ((filter (x: x ? "imageName") (builtins.attrValues self)))}
    '';
  });
}
