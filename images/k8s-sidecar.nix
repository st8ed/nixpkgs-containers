{ pkgs, python3, fetchFromGitHub, dockerTools, cacert }:

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

    # iana-etc
    # dockerTools.binSh
    # dockerTools.usrBinEnv

    (pkgs.buildEnv {
      name = "k8s-sidecar-env";
      extraPrefix = "/run/system";
      paths = [
        # bash coreutils
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
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
