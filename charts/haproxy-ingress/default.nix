{ pkgs, stdenv, chartTools, dockerImages, yq-go }:

let
  inherit (dockerImages) haproxy-ingress haproxy;

in
stdenv.mkDerivation rec {
  pname = "haproxy-ingress";
  version = "0.14.2";

  src = pkgs.fetchFromGitHub {
    owner = "haproxy-ingress";
    repo = "charts";
    rev = "${version}";
    hash = "sha256-abFwBIS8Z5d3nFhhZQ+W6LG0iXfdb8u6D01GoeiqoTA=";
  };

  patches = [
    ./patch-sa-access.patch
  ];

  buildInputs = [ yq-go ];
  buildPhase = ''
    pushd haproxy-ingress

    ${chartTools.patchYaml "values.yaml" haproxy-ingress.manifest {
      ".controller.image.repository" = ".repository";
      ".controller.image.tag" = ''.tag + "@" + .digest'';
    }}
    ${chartTools.patchYaml "values.yaml" haproxy.manifest {
      ".controller.haproxy.image.repository" = ".repository";
      ".controller.haproxy.image.tag" = ''.tag + "@" + .digest'';
    }}

    yq --inplace --from-file /dev/stdin values.yaml <<EOT
      .

      | .controller.metrics.image.pullPolicy = "Never"
      | .controller.logs.image.pullPolicy = "Never"
      | .defaultBackend.image.pullPolicy = "Never"

      | .controller.service.type = "NodePort"
      | .controller.terminationGracePeriodSeconds = "10"

      | .controller.haproxy.enabled = true
      | .controller.containerPorts.http = 8080
      | .controller.containerPorts.https = 8443
      | .controller.config = {
        "bind-http": ":::8080,:8080",
        "bind-https": ":::8443,:8443",
        "use-haproxy-user": "true"
      }

      | .controller.haproxy.resources.requests = {
            "cpu": "100m",
            "memory": "64Mi"
      }
      | .controller.haproxy.resources.limits = {
            "cpu": "1",
            "memory": "256Mi"
      }

      | .controller.ingressClassResource.enabled = "true"
      | .controller.ingressClassResource.default = "true"
    EOT

    popd
  '';

  installPhase = ''
    # FIXME: Helm kubeVersion is incorrect in some cases
    sed -i 's/apiVersion: policy\/v1beta1/apiVersion: policy\/v1/' haproxy-ingress/templates/controller-poddisruptionbudget.yaml
    mv haproxy-ingress $out
  '';
}
