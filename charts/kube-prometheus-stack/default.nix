{ pkgs, stdenv, fetchurl, dockerImages, chartTools, yq-go, dockerTools }:

let
  inherit (dockerImages)
    prometheus
    prometheus-alertmanager
    prometheus-operator
    prometheus-config-reloader
    grafana
    busybox
    k8s-sidecar
    curl
    kube-state-metrics;

  # The chart uses inconsistent image specification, so there are
  # two variants for patching images

  patchImage = path: image: chartTools.patchYaml "values.yaml" image.manifest
    {
      "${path}.registry" = ".registry";
      "${path}.repository" = ''.registry as $r | .repository | sub($r+"/", "")'';
      "${path}.tag" = ".tag";
      "${path}.sha" = ''.digest | sub("sha256:", "")'';
    };

  patchImage2 = path: image: chartTools.patchYaml "values.yaml" image.manifest
    {
      # Registry is specified in .global.imageRegistry
      "${path}.repository" = ".repository";
      "${path}.tag" = ".tag";
      "${path}.sha" = ''.digest | sub("sha256:", "")'';
    };

in
stdenv.mkDerivation rec {
  pname = "kube-prometheus-stack";
  version = "43.1.1";

  src = fetchurl {
    url = "https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-${version}/kube-prometheus-stack-${version}.tgz";
    hash = "sha256-hQsRt0X3lGOXzeTxaD88mnTuC12AP2407HgqBaLbZiU=";
  };

  patches = [ ./fixes.patch ];

  buildInputs = [ yq-go ];
  buildPhase = ''
    yq --inplace '.global.imageRegistry = "${dockerTools.options.registry}"' values.yaml
    yq --inplace '.nodeExporter.enabled = false' values.yaml

    ${patchImage ".prometheus.prometheusSpec.image" prometheus}
    ${patchImage ".alertmanager.alertmanagerSpec.image" prometheus-alertmanager}
    ${patchImage ".prometheusOperator.image" prometheus-operator}
    ${patchImage ".prometheusOperator.prometheusConfigReloader.image" prometheus-config-reloader}

    (cd charts/grafana;
      ${patchImage2 ".image" grafana}
      ${patchImage2 ".initChownData.image" busybox}
      ${patchImage2 ".sidecar.image" k8s-sidecar}
      ${patchImage2 ".downloadDashboardsImage" curl}
      yq --inplace '.testFramework.enabled = false' values.yaml

      # TODO: Substitute this image
      yq --inplace '.imageRenderer.image = ""' values.yaml
    )

    (cd charts/kube-state-metrics;
      ${patchImage2 ".image" kube-state-metrics}
    )

    # TODO: Thanos image
  '';

  installPhase = ''
    cp -r . $out
  '';
}
