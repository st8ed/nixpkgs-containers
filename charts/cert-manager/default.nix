{ pkgs, lib, stdenv, chartTools, dockerImages, yq-go, cert-manager, gnused }:

stdenv.mkDerivation rec {
  pname = "cert-manager";
  version = cert-manager.version;

  src = pkgs.fetchurl {
    url = "https://charts.jetstack.io/charts/cert-manager-v${version}.tgz";
    sha256 = "sha256-Oeuq2Bz3NoZD/FYWJ1svnhnZg3zPEK5/lTF4XvTgNkY=";
  };

  buildInputs = [ yq-go gnused ];
  buildPhase = ''
    ${
      lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: chartTools.patchYaml "values.yaml" v {
        "${k}.repository" = ".repository";
        "${k}.tag" = ".tag";
        "${k}.digest" = ".digest";
      }) {
        ".image" = dockerImages.cert-manager-controller.manifest;
        ".acmesolver.image" = dockerImages.cert-manager-acmesolver.manifest;
        ".cainjector.image" = dockerImages.cert-manager-cainjector.manifest;
        ".webhook.image" = dockerImages.cert-manager-webhook.manifest;
        ".startupapicheck.image" = dockerImages.cert-manager-ctl.manifest;
      })
    }

    # FIXME: Helm kubeVersion is incorrect in some cases
    sed -i '/kubeVersion:/d' Chart.yaml
  '';

  installPhase = ''
    cd ..
    mv cert-manager $out
  '';
}
