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

      overlay = pkgs: super: {
        haproxy-ingress = pkgs.callPackage ./pkgs/haproxy-ingress.nix { };

        gitea-docker-entrypoint = pkgs.callPackage ./pkgs/gitea-docker-entrypoint.nix {
          gitea = pkgs.gitea.override {
            pamSupport = false;
          };
        };

        dockerImages = pkgs.lib.makeScope super.newScope (self: {
          busybox = pkgs.callPackage ./images/busybox.nix { };
          code-server = pkgs.callPackage ./images/code-server.nix { };
          docker-registry = pkgs.callPackage ./images/docker-registry.nix { };

          gitea = pkgs.callPackage ./images/gitea.nix { };
          grafana = pkgs.callPackage ./images/grafana.nix { };

          haproxy = pkgs.callPackage ./images/haproxy.nix { };
          haproxy-ingress = pkgs.callPackage ./images/haproxy-ingress.nix { };

          home-assistant = pkgs.callPackage ./images/home-assistant.nix { };
          k8s-sidecar = pkgs.callPackage ./images/k8s-sidecar.nix { };
          minio = pkgs.callPackage ./images/minio.nix { };
          mopidy = pkgs.callPackage ./images/mopidy.nix { };
        });
      };
    in
    {
      packages = forAllSystems (system: nixpkgsFor."${system}".dockerImages);
      ci = forAllSystems (system: (import ./ci.nix) nixpkgsFor."${system}");

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
              dest="$2/$1:${pkgs.dockerLib.rev}"

              digest_file=$(mktemp imageDigest-XXXX)

              extension="''${src##*.}"

              if [ "$extension" = "gz" ]; then
                 skopeo copy  --insecure-policy \
                      docker-archive:/dev/stdin \
                      docker://"$dest" \
                      --digestfile "$digest_file" <"$src"
              else
                "$src" | gzip --fast \
                    | skopeo copy  --insecure-policy \
                        docker-archive:/dev/stdin \
                        docker://"$dest" \
                        --digestfile "$digest_file"
              fi

              echo "$dest@$(cat "$digest_file")" >> digests
              rm -f "$digest_file"
            '';
          };
        });

      overlay = lib.composeManyExtensions [
        (import ./lib.nix)
        (pkgs: super: {
          dockerTools = super.dockerTools.overrideScope' (self: super: {
            options = super.options.overrideScope' (_: _: {
              rev = "${lib.substring 0 8 (nixpkgs.lastModifiedDate or nixpkgs.lastModified or "19700101")}.${nixpkgs.shortRev or "dirty"}";
              enableStreaming = true;
              includeStorePaths = true;
            });
          });
        })
        overlay
      ];
    };
}
