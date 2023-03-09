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

      repositoryPrefix = "docker.io/st8ed/";
      registry = "docker.io";
      namespace = "com.st8ed.";

      forAllSystems = lib.genAttrs supportedSystems;
      nixpkgsFor = lib.genAttrs supportedSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      inherit repositoryPrefix;

      packages = forAllSystems (system: with nixpkgsFor."${system}";
        dockerImages // flatpakImages
        // { inherit helmCharts kustomizePackages; }
        // { inherit dockerTools chartTools; }
        // { ci = callPackage ./ci.nix { }; }
        // { inherit pkgs; }
      );

      overlay = lib.composeManyExtensions [
        (import ./lib/dockerTools.nix)
        (import ./lib/flatpakTools.nix)
        (import ./lib/chartTools.nix)
        (import ./lib/kustomizeTools.nix)
        (pkgs: super: {
          dockerTools = super.dockerTools.overrideScope' (self: super: {
            options = super.options.overrideScope' (_: _: {
              inherit repositoryPrefix registry;
            });
          });

          flatpakTools = super.flatpakTools.overrideScope' (self: super: {
            options = super.options.overrideScope' (_: _: {
              inherit namespace;
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
        (import ./pkgs/dockerImages.nix)
        (import ./pkgs/flatpakImages.nix)
        (import ./pkgs/helmCharts.nix)
        (import ./pkgs/kustomizePackages.nix)
      ];
    };
}
