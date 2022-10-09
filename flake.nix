{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs } @ inputs:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = lib.genAttrs supportedSystems;
      nixpkgsFor = lib.genAttrs supportedSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      packages = forAllSystems (system: with nixpkgsFor."${system}"; dockerImages // { inherit helmCharts README; });
      apps = forAllSystems (system: nixpkgsFor."${system}".callPackage ./ci.nix { });

      overlay = lib.composeManyExtensions [
        (import ./lib/dockerTools.nix)
        (import ./lib/chartTools.nix)
        (pkgs: super: {
          dockerTools = super.dockerTools.overrideScope' (self: super: {
            options = super.options.overrideScope' (_: _: {
              rev = "${lib.substring 0 8 (nixpkgs.lastModifiedDate or nixpkgs.lastModified or "19700101")}.${nixpkgs.shortRev or "dirty"}";
              enableStreaming = true;
              includeStorePaths = true;
            });
          });
        })
        (import ./images.nix)
        (import ./charts.nix)
      ];

      all = with self.packages.x86_64-linux; nixpkgsFor.x86_64-linux.linkFarmFromDrvs "nixpkgs-containers-all" [
        bind
        busybox
        code-server
        docker-registry
        gitea
        grafana
        haproxy-ingress
        haproxy
        # home-assistant
        kube-state-metrics
        minio
        # mopidy
        nfs-ganesha
        prometheus-admission-webhook
        prometheus-alertmanager
        prometheus-config-reloader
        # prometheus-operator
        # prometheus
        socat
        transmission

        helmCharts.bind
        helmCharts.gitea
        helmCharts.nfs-ganesha
        helmCharts.transmission
      ];
    };
}
