{ pkgs, ... }: {
  push = with pkgs; let
    program = writeShellApplication {
      name = "nixpkgs-containers-push";
      runtimeInputs = [ skopeo gzip jq ];
      text = ''
        src="$(nix build \
            "$1" \
             --no-link --json | jq -r .[0].outputs.out
        )"

        dest=$2/$(nix eval --raw "$1" --apply 'x: x.imageName + ":" + x.imageTag')
        extension=''${src##*.}

        printf "%s@" "$dest" >> digests

        if [ "$extension" = "gz" ]; then
           skopeo copy --insecure-policy \
                docker-archive:/dev/stdin \
                "docker://$dest" \
                --digestfile >(tee -a digests) <"$src"
        else
          "$src" | gzip --fast \
              | skopeo copy --insecure-policy \
                  docker-archive:/dev/stdin \
                  "docker://$dest" \
                  --digestfile >(tee -a digests)
        fi

        printf "\n" >> digests
      '';
    };
  in
  {
    type = "app";
    program = "${program}/bin/${program.meta.mainProgram}";
  };
}
