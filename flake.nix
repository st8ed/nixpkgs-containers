{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixng.url = "github:nix-community/NixNG/8255f9e12d8d39e82c6047835e21577f1b8284c3";
    nixng.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixng } @ inputs:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      # This prefix is used in all images and changing it will
      # force rebuild of every image tarball.
      # Can be empty.
      repositoryPrefix = "st8ed/";

      # This registry is be backed into all image tarballs' metadata,
      # but not the actual image tarballs. It is used for refencing default
      # image sources in Helm charts.
      # Changing leads to rebuild of every image tarball.
      # Can be empty.
      registry = "docker.io";

      forAllSystems = lib.genAttrs supportedSystems;
      nixpkgsFor = lib.genAttrs supportedSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      packages = forAllSystems (system: with nixpkgsFor."${system}";
        dockerImages
        // { inherit helmCharts; }
        // { ci = callPackage ./ci.nix { }; }
      );

      overlay = lib.composeManyExtensions [
        (import ./lib/dockerTools.nix)
        (import ./lib/chartTools.nix)
        (pkgs: super: {
          dockerTools = super.dockerTools.overrideScope' (self: super: {
            options = super.options.overrideScope' (_: _: {
              inherit repositoryPrefix registry;
            });
          });

          makeNgSystem = name: config: nixng.nglib.makeSystem {
            system = pkgs.system;
            nixpkgs = with pkgs; {
              inherit lib;
              legacyPackages."${system}" = pkgs;
            };

            inherit name config;
          };
        })
        (import ./images.nix)
        (import ./charts.nix)
      ];
    };
}
