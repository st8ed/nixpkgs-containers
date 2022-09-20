pkgs: super: {
  helmCharts = pkgs.lib.makeScope super.newScope (self: {
    bind = pkgs.callPackage ./charts/bind.nix { };
    gitea = pkgs.callPackage ./charts/gitea { };
    nfs-ganesha = pkgs.callPackage ./charts/nfs-ganesha.nix { };
    transmission = pkgs.callPackage ./charts/transmission.nix { };
  });
}
