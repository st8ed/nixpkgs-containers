{ pkgs, lib, dockerTools, python3, cacert }:

let
  src = pkgs.fetchFromGitHub {
    owner = "kiwigrid";
    repo = "k8s-sidecar";
    rev = "1.18.1";
    sha256 = "sha256-CowI9G1fmvgKrhRHF8V0Fq/PyNksj67EtAPdjQkUhRE=";
  };

  rootfs = pkgs.runCommandNoCC "k8s-sidecar" { inherit src; } ''
    mkdir -p $out/app
    cp -r $src/src/* $out/app
  '';

in
dockerTools.build {
  name = "k8s-sidecar";
  tag = "v${src.rev}";

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
    replacementImage = "docker.io/kiwigrid/k8s-sidecar";
    replacementImageUrl = "https://github.com/kiwigrid/k8s-sidecar/blob/master/Dockerfile";

    license = licenses.mit;
    platform = platforms.linux;
  };
}
