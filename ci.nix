{ pkgs, ... }:
let
  allImages = pkgs.lib.filterAttrs (n: v: v ? imageName) pkgs.dockerImages;
  allCharts = pkgs.lib.filterAttrs (n: v: (builtins.typeOf v) == "set") pkgs.helmCharts;

in
{
  images = with pkgs; linkFarmFromDrvs "nixpkgs-containers" (
    builtins.attrValues allImages
  );

  streams = with pkgs; linkFarmFromDrvs "nixpkgs-containers" (
    map (v: v.stream) (builtins.attrValues allImages)
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
        local flakeUri=$1
        local out
        local manifest
          
        read -r -d '\n' out \
          < <(nix path-info "$flakeUri" 2>/dev/null) \
          || true
          
        if [ -z "$out" ]; then
          echo "Unable to get package path for $flakeUri. Is it built?" >&2
          exit 1
        fi
          
        read -r -d '\n' manifest \
          < <(nix path-info "$flakeUri.manifest" 2>/dev/null) \
          || true

        repository=$(jq -r '.repository' "$manifest")
        tag=$(jq -r '.tag' "$manifest")

        skopeo copy \
            "oci-archive:$out" \
            "docker://$registry/$repository:$tag"

        skopeo copy \
            "oci-archive:$out" \
            "docker://$registry/$repository:latest"
      }

      for name in "''${repositories[@]}"; do
        publish "${builtins.toString ./.}#$name"
      done
    '';
  };

  README = with pkgs; let
    pkg = with lib; writeText "README.md" ''
      | Image  | Replacement image | Description |
      |---|---|---|
      ${concatMapStringsSep "\n" (v:
      "| ${v.imageName}:${v.imageTag} " +
      "| ${optionalString (v.meta ? replacementImage)
        "[${v.meta.replacementImage}](${v.meta.replacementImageUrl})"
      } " +
      "| ${optionalString (v.meta ? description) v.meta.description} " +
      "|"
      ) (builtins.attrValues allImages)}
    '';

  in
  writeShellApplication {
    name = "nixpkgs-containers-update-readme";
    text = ''
      cp -vf "${pkg}" ./README.md
    '';
  };
}
