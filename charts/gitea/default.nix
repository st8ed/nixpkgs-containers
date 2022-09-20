{ stdenv, fetchurl, dockerImages, gnused }:

let
  image = {
    repository = "registry.st8ed.com/gitea";
    tag = "1.16.5@sha256:0aab89fbfb50e3057d3f0cf9d2069a112cd21820d34a18b2e2872aee3a7637f3";
  };

in
stdenv.mkDerivation {
  name = "gitea";
  version = "5.0.4";

  src = fetchurl {
    url = "https://dl.gitea.io/charts/gitea-5.0.4.tgz";
    sha256 = "sha256-0+mOntkGA6DI0xQeHHRfLNwpnf0V7axu8ISiv1wEZPU=";
  };

  patches = [
    ./gitea-patch-pullPolicy.patch
    ./gitea-patch-tagOverride.patch
  ];

  unpackPhase = ''
    tar xvf $src -C .
  '';

  buildInputs = [ gnused ];
  buildPhase = ''
    sed -i 's|^  repository:.*|  repository: ${image.repository}|g' gitea/values.yaml
    sed -i 's|^  tagOverride:.*|  tagOverride: ${image.tag}|g' gitea/values.yaml
    sed -i 's|^  rootless:.*|  rootless: true|g' gitea/values.yaml
  '';

  installPhase = ''
    mv gitea $out
  '';
}
