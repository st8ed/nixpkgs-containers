pkgs: {
  push = with pkgs; writeShellApplication {
    name = "nixpkgs-containers-push";
    runtimeInputs = [ skopeo gzip jq ];
    text = ''
      src="$(nix build \
          "$1" \
           --no-link --json | jq -r .[0].outputs.out
      )"
      dest="$(nix eval "$1" --apply 'x: x.imageName + ":" + x.imageTag')"

      digest_file=$(mktemp imageDigest-XXXX)

      extension="''${src##*.}"

      if [ "$extension" = "gz" ]; then
         skopeo copy --insecure-policy \
              docker-archive:/dev/stdin \
              docker://"$dest" \
              --digestfile "$digest_file" <"$src"
      else
        "$src" | gzip --fast \
            | skopeo copy --insecure-policy \
                docker-archive:/dev/stdin \
                docker://"$dest" \
                --digestfile "$digest_file"
      fi

      echo "$dest@$(cat "$digest_file")" >> digests
      rm -f "$digest_file"
    '';
  };
}
