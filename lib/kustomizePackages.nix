pkgs: super: {
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

  kustomizePackages.flannel = pkgs.runCommand "flannel.yaml"
    {
      buildInputs = with pkgs; [ kustomize yq-go gnused ];

      inherit (pkgs.flannel) src;

      kustomization = with pkgs; lib.generators.toYAML { } {
        resources = [
          "kube-flannel.yaml"
        ];

        transformers = [
          (pkgs.kustomizeTransformers.images {
            # TODO: This is for new version:
            #"docker.io/flannel/flannel" =
            #  dockerImages.flannel;
            #"docker.io/flannel/flannel-cni-plugin" =
            #  dockerImages.flannel-cni-plugin;
            "docker.io/rancher/mirrored-flannelcni-flannel" =
              dockerImages.flannel;
            "docker.io/rancher/mirrored-flannelcni-flannel-cni-plugin" =
              dockerImages.flannel-cni-plugin;
          })
        ];
      };

      passAsFile = [ "kustomization" ];
    } ''
    cp $src/Documentation/kube-flannel.yml kube-flannel.yaml

    sed -i 's/app:\s*\(flannel\)$/app.kubernetes.io\/name: \1/' kube-flannel.yaml
    sed -i '/tier:\s*\(node\)$/d' kube-flannel.yaml

    mkdir -p $out/etc/kubernetes/manifests

    cp $kustomizationPath kustomization.yaml
    kustomize build \
      --load-restrictor "LoadRestrictionsNone" \
      --output $out/etc/kubernetes/manifests/flannel.yaml
  '';
}
