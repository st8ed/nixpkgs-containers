{ pkgs, ... }:
let
  allImages = pkgs.lib.filterAttrs (n: v: v ? imageName) pkgs.dockerImages;
  allCharts = pkgs.lib.filterAttrs (n: v: (builtins.typeOf v) == "set") pkgs.helmCharts;

in
rec {
  images = with pkgs; linkFarmFromDrvs "nixpkgs-containers" (
    builtins.attrValues allImages
  );

  streams = with pkgs; linkFarmFromDrvs "nixpkgs-containers" (
    map (v: v.stream) (builtins.attrValues allImages)
  );

  manifests = with pkgs; linkFarm "nixpkgs-containers" (
    pkgs.lib.mapAttrsToList (n: v: { name = n; path = v.manifest; }) allImages
  );

  charts = with pkgs; linkFarmFromDrvs "nixpkgs-containers-charts" (
    builtins.attrValues allCharts
  );

  print-digests = with pkgs; writeShellApplication {
    name = "nixpkgs-containers-print-digests";
    text = ''
      ${lib.concatStringsSep "\n" (map (v: ''
        jq -r '.repository + ":" + .tag + "@" + .digest' ${v.manifest}
      '') (builtins.attrValues allImages))}
    '';
  };

  publish = with pkgs; writeShellApplication {
    name = "nixpkgs-containers-publish";
    runtimeInputs = [ skopeo jq ];
    text = ''
      # Note: it uses "nix" from PATH

      registry=$1
      shift 1

      repositories=()

      if [ $# -eq 0 ]; then
        echo Publishing all images
        repositories=(${lib.escapeShellArgs (builtins.attrNames allImages)})
      else
        echo Publishing specified images
        repositories=("$@")
      fi


      function publish() {
        local manifest="${manifests}/$1"

        repository=$(jq -r '.repository' "$manifest")
        tag=$(jq -r '.tag' "$manifest")
        archive=$(jq -r '."oci-archive"' "$manifest")

        for _tag in "$tag" latest; do
          echo "Pushing $registry/$repository:$_tag"

          skopeo copy --quiet \
              --dest-precompute-digests \
              "oci-archive:$archive" \
              "docker://$registry/$repository:$_tag"
        done
      }

      for name in "''${repositories[@]}"; do
        publish "$name"
      done
    '';
  };

  README = with pkgs; let
    pkg = with lib; writeText "README.md" ''
      This repository contains a collection of OCI container images & Helm charts built with Nix.
      Most of images mimic specificied replacement images.

      | Image  | Drop-in replacement image |
      |---|---|
      ${concatMapStringsSep "\n" (v:
      "| ${v.imageName}:${v.imageTag} " +
      "| ${optionalString (v.meta ? replacementImage)
        "[${v.meta.replacementImage}](${v.meta.replacementImageUrl})"
      } " +
      # "| ${optionalString (v.meta ? description) v.meta.description} " +
      "|"
      ) (builtins.attrValues allImages)}
    '';

  in
  writeShellApplication {
    name = "nixpkgs-containers-update-readme";
    text = ''
      cp -vf ${pkg} ./README.md
    '';
  };
}
