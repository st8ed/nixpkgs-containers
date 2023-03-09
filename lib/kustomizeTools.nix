pkgs: super: {
  # TODO: PullPolicy: Never transformer

  kustomizeTransformers.images = images: with pkgs; runCommand "kustomization-images-transformers.yaml"
    {
      buildInputs = [ yq-go ];

      kustomization = lib.generators.toYAML { } (lib.mapAttrsToList
        (k: v: {
          apiVersion = "builtin";
          kind = "ImageTagTransformer";
          metadata.name = "nix-image-transformer" + (baseNameOf k);
          imageTag = {
            name = k;
            newName = v.imageName;
            newTag = v.imageTag;
            digest = v.manifest; # Will be patched
          };
        })
        images);

      passAsFile = [ "kustomization" ];
    } ''
    yq eval -P \
      'map(.imageTag.digest = load(.imageTag.digest).digest) | .[] | split_doc' \
      $kustomizationPath >$out
  '';

  kustomizeTools.build = { pname, version, kustomization, split ? false } @ args: pkgs.stdenv.mkDerivation
    {
      inherit pname version;
      name = if !split then "${pname}-${version}.yaml" else "${pname}-${version}";

      buildInputs = with pkgs; [ kustomize ] ++ (lib.optional split yq-go);
      kustomization = with pkgs; lib.generators.toYAML { } kustomization;
      passAsFile = [ "kustomization" ];

      passthru = {
        split = pkgs.kustomizeTools.build (args // { split = true; });
      };

      buildCommand = ''
        mkdir ./base
        mv $kustomizationPath ./base/kustomization.yaml
        kustomize build \
          --load-restrictor "LoadRestrictionsNone" \
          ./base \
          --output manifest.yaml

        ${if !split then ''
          mv manifest.yaml $out
        '' else ''
          mkdir -p $out
          manifest=$(realpath ./manifest.yaml)
          (cd $out; yq -P -s '.kind + "_" + $index + ".yaml"' "$manifest")
        ''}
      '';
    };
}
