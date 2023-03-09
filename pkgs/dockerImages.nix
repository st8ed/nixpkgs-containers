pkgs: super: {
  dockerImages = pkgs.lib.makeScope super.newScope (self: {
    bind = pkgs.callPackage ../images/bind.nix { };
    busybox = pkgs.callPackage ../images/busybox.nix { };
    # code-server = pkgs.callPackage ../images/code-server.nix { };
    coredns = pkgs.callPackage ../images/coredns.nix { };
    curl = pkgs.callPackage ../images/curl.nix { };
    docker-registry = pkgs.callPackage ../images/docker-registry.nix { };
    etcd = pkgs.callPackage ../images/etcd.nix { };
    flannel = pkgs.callPackage ../images/flannel.nix { };
    flannel-cni-plugin = pkgs.callPackage ../images/flannel-cni-plugin.nix { };
    gitea = pkgs.callPackage ../images/gitea.nix { };
    grafana = pkgs.callPackage ../images/grafana.nix { };
    haproxy-ingress = pkgs.callPackage ../images/haproxy-ingress.nix { };
    haproxy = pkgs.callPackage ../images/haproxy.nix { };
    # home-assistant = pkgs.callPackage ../images/home-assistant.nix { };
    # hydra = pkgs.callPackage ../images/hydra.nix { };
    k8s-sidecar = pkgs.callPackage ../images/k8s-sidecar.nix { };
    minio = pkgs.callPackage ../images/minio.nix { };
    # mopidy = pkgs.callPackage ../images/mopidy.nix { };
    nfs-ganesha = pkgs.callPackage ../images/nfs-ganesha.nix { };
    nix-daemon = pkgs.callPackage ../images/nix-daemon.nix { };
    postgresql = pkgs.callPackage ../images/postgresql.nix { };
    prometheus-admission-webhook = pkgs.callPackage ../images/prometheus-admission-webhook.nix { };
    prometheus-alertmanager = pkgs.callPackage ../images/prometheus-alertmanager.nix { };
    prometheus-config-reloader = pkgs.callPackage ../images/prometheus-config-reloader.nix { };
    prometheus-operator = pkgs.callPackage ../images/prometheus-operator.nix { };
    prometheus = pkgs.callPackage ../images/prometheus.nix { };
    socat = pkgs.callPackage ../images/socat.nix { };
    transmission = pkgs.callPackage ../images/transmission.nix { };

    openebs-lvm-driver = pkgs.callPackage ../images/openebs-lvm-driver.nix { };

    inherit (pkgs.callPackage ../images/kubernetes/common.nix { })
      pause
      kube-apiserver
      kube-controller-manager
      kube-scheduler
      kube-proxy;

    inherit (pkgs.callPackage ../images/kubernetes/csi.nix { })
      kube-csi-provisioner
      kube-csi-resizer
      kube-csi-snapshotter
      kube-csi-snapshot-controller
      kube-csi-snapshot-validation-webhook
      kube-csi-node-driver-registrar;

    inherit (pkgs.callPackage ../images/cert-manager.nix { })
      cert-manager-controller
      cert-manager-acmesolver
      cert-manager-cainjector
      cert-manager-webhook
      cert-manager-ctl;

    kube-state-metrics = pkgs.callPackage ../images/kubernetes/state-metrics.nix { };
  });

  inherit (pkgs.callPackage ../images/cert-manager.nix { })
    cert-manager;


  gitea-docker-entrypoint = pkgs.callPackage ./gitea-docker-entrypoint.nix {
    gitea = pkgs.gitea.override {
      pamSupport = false;
    };
  };

  haproxy = pkgs.callPackage ./haproxy.nix {
    inherit (super) haproxy;
  };

  haproxy-ingress = pkgs.callPackage ./haproxy-ingress.nix { };
  prometheus-operator = pkgs.callPackage ./prometheus-operator.nix { };
}
