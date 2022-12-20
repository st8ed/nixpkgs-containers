{ pkgs, stdenv, chartTools, dockerImages, yq-go }:

let
  inherit (dockerImages) haproxy-ingress haproxy;

in
stdenv.mkDerivation rec {
  pname = "haproxy-ingress";
  version = "0.13.9";

  src = pkgs.fetchFromGitHub {
    owner = "haproxy-ingress";
    repo = "charts";
    rev = "${version}";
    hash = "sha256-2Vg66fw/pZ6RVcYFJ1ClfZ+xHrtrZBRIeMjo9MAJSHA=";
  };

  buildInputs = [ yq-go ];
  buildPhase = ''
    pushd haproxy-ingress

    # TODO: Substitute these images too
    yq --inplace '.controller.metrics.image.pullPolicy = "Never"' values.yaml
    yq --inplace '.controller.logs.image.pullPolicy = "Never"' values.yaml
    yq --inplace '.defaultBackend.image.pullPolicy = "Never"' values.yaml

    ${chartTools.patchYaml "values.yaml" haproxy-ingress.manifest {
      ".controller.image.repository" = ''.registry + "/" + .repository'';
      ".controller.image.tag" = ''.tag + "@" + .digest'';
    }}
    ${chartTools.patchYaml "values.yaml" haproxy.manifest {
      ".controller.haproxy.image.repository" = ''.registry + "/" + .repository'';
      ".controller.haproxy.image.tag" = ''.tag + "@" + .digest'';
    }}

    popd
  '';

  installPhase = ''
    rm haproxy-ingress/templates/controller-poddisruptionbudget.yaml
    mv haproxy-ingress $out
  '';
}
