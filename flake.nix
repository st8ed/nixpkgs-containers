{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/master";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable } @ inputs:
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
      packages = forAllSystems (system: nixpkgsFor."${system}".dockerImages);

      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor."${system}";
        in
        rec {
          push = pkgs.writeShellApplication {
            name = "nixpkgs-containers-push";
            runtimeInputs = with pkgs; [ skopeo gzip jq ];
            text = ''
              src="$(nix build \
                  ".#$1" \
                   --no-link --json | jq -r .[0].outputs.out
              )"
              dest="$2/library/$1:${pkgs.dockerLib.rev}"

              digest_file=$(mktemp imageDigest-XXXX)
              "$src" | gzip --fast \
                  | skopeo copy  --insecure-policy \
                      docker-archive:/dev/stdin \
                      docker://"$dest" \
                      --digestfile "$digest_file"

              echo "$dest@$(cat "$digest_file")" >> digests
              rm -f "$digest_file"
            '';
          };
        });

      overlay = lib.composeManyExtensions [
        (import ./lib.nix)
        (pkgs: super: {
          dockerLib = super.dockerLib.overrideScope' (self: super: {
            rev = "${lib.substring 0 8 (nixpkgs.lastModifiedDate or nixpkgs.lastModified or "19700101")}.${nixpkgs.shortRev or "dirty"}";
            enableStreaming = true; # if inputs.self ? shortRev then false else true;
            includeStorePaths = true;
          });

          dockerImages = pkgs.lib.makeScope super.newScope (self: {
            docker-registry = pkgs.callPackage ./images/docker-registry.nix { };

            gitea = pkgs.callPackage ./images/gitea {
              # Pick fresh version from unstable
              gitea = pkgs.callPackage
                (
                  nixpkgs-unstable.legacyPackages."${super.system}".gitea.override
                )
                {
                  buildGoPackage = super.buildGo117Package;
                };
            };

            haproxy = pkgs.callPackage ./images/haproxy/image-haproxy.nix { };
            haproxy-ingress = pkgs.callPackage ./images/haproxy/image-ingress.nix {
              haproxy-ingress = pkgs.callPackage ./images/haproxy/ingress.nix { };
            };

            home-assistant = pkgs.callPackage ./images/home-assistant.nix { };
            minio = pkgs.callPackage ./images/minio.nix { };
            mopidy = pkgs.callPackage ./images/mopidy.nix { };
          });
        })
      ];
    };
}
