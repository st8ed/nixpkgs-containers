{ lib, go, buildGoModule, dockerTools, fetchFromGitHub }:

let
  cert-manager = buildGoModule rec {
    pname = "cert-manager";
    version = "1.11.0";

    src = fetchFromGitHub {
      owner = "cert-manager";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-SB2GJg4qaAg2EZafZpSTd1N8MYpE/jCFLBy9ZwCrejM=";
    };

    vendorSha256 = "sha256-aLEQoNt/5ikMw+wExSUITey/68Gk4+dsRbSydsiEiEg=";
    CGO_ENABLED = "0";

    ldflags = [
      "-s"
      "-w"
      "-X main.version=v${version}"
    ];

    # Takes too much time
    doCheck = false;

    subPackages = [
      "cmd/*"
    ];
  };

  mkImage = name: package: binary: dockerTools.build {
    inherit name;
    tag = package.version;

    extraCommands = ''
      mkdir -p ./app/cmd/${binary}
      cp ${package}/bin/${binary} ./app/cmd/${binary}/${binary}
    '';

    config = {
      Entrypoint = [ "/app/cmd/${binary}/${binary}" ];
      User = "1000:1000";
    };

    meta = with lib; {
      description = "Certificate provisioner";
      replacementImage = "quay.io/jetstack/${name}";
      replacementImageUrl = "https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.${binary}";

      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };
in
{
  inherit cert-manager;

  cert-manager-controller = mkImage "cert-manager-controller" cert-manager "controller";
  cert-manager-acmesolver = mkImage "cert-manager-acmesolver" cert-manager "acmesolver";
  cert-manager-cainjector = mkImage "cert-manager-cainjector" cert-manager "cainjector";
  cert-manager-webhook = mkImage "cert-manager-webhook" cert-manager "webhook";
  cert-manager-ctl = mkImage "cert-manager-ctl" cert-manager "ctl";
}
