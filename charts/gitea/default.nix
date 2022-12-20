{ pkgs, stdenv, chartTools, dockerImages }:

let
  inherit (dockerImages) gitea;

in
stdenv.mkDerivation {
  pname = "gitea";
  version = "5.0.4";

  src = pkgs.fetchurl {
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

  buildPhase = ''
    ${chartTools.patchYaml "gitea/values.yaml" gitea.manifest {
      ".image.repository" = ''.registry + "/" + .repository'';
      ".image.tagOverride" = ''.tag + "@" + .digest'';
      ".image.rootless" = "true";
      ".image.pullPolicy" = ''"IfNotPresent"'';
    }}
  '';

  installPhase = ''
    mv gitea $out
  '';
}
