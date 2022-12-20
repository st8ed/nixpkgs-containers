pkgs: super: {
  helmCharts = pkgs.lib.makeScope super.newScope (self: {
    bind = pkgs.callPackage ./charts/bind.nix { };
    gitea = pkgs.callPackage ./charts/gitea { };
    haproxy-ingress = pkgs.callPackage ./charts/haproxy-ingress.nix { };
    kube-prometheus-stack = pkgs.callPackage ./charts/kube-prometheus-stack { };
    nfs-ganesha = pkgs.callPackage ./charts/nfs-ganesha.nix { };
    postgresql = pkgs.callPackage ./charts/postgresql.nix { };
    transmission = pkgs.callPackage ./charts/transmission.nix { };
  });
}
