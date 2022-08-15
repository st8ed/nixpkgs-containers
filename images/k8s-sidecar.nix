{ pkgs, lib, python3, fetchFromGitHub, dockerTools, cacert }:

let
  src = fetchFromGitHub {
    owner = "kiwigrid";
    repo = "k8s-sidecar";
    rev = "1.18.0";
    sha256 = "sha256-4oE63j0M5V2AcGC/JsT2auxD6Y0zVFQ2iFuE+F4P9jA=";
  };

  rootfs = pkgs.runCommandNoCC "k8s-sidecar" { inherit src; } ''
    mkdir -p $out/app
    cp -r $src/src/* $out/app
  '';

in
dockerTools.build {
  name = "k8s-sidecar";
  tag = src.rev;

  contents = [
    rootfs

    (pkgs.buildEnv {
      name = "k8s-sidecar-env";
      extraPrefix = "/run/system";
      paths = [
        cacert

        (python3.withPackages (p: with p; [ kubernetes requests ]))
      ];
    })
  ];

  config = {
    Entrypoint = [ "python" "-u" "/app/sidecar.py" ];
    Cmd = [ ];

    User = "65534:65534";

    Env = [
      "PATH=/usr/local/bin:/run/system/bin:/bin"
      "SSL_CERT_FILE=/run/system/etc/ssl/certs/ca-bundle.crt"
    ];
  };

  meta = with lib; {
    description = "Collect configmaps and store them in a path";
    replacementImage = "kiwigrid/k8s-sidecar";
    replacementImageUrl = "https://github.com/kiwigrid/k8s-sidecar/blob/master/Dockerfile";

    license = licenses.mit;
    platform = platforms.linux;
  };
}
