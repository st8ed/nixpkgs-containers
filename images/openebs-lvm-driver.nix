{ pkgs, lib, go, dockerTools, buildGoModule }:

let
  binary = "lvm-driver";

  package = buildGoModule rec {
    pname = "openebs-lvm-driver";
    version = "1.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "openebs";
      repo = "lvm-localpv";
      rev = "lvm-localpv-${version}";
      sha256 = "sha256-UfqGHSNnOFcZfMt/j1sIy1juuozUIopgShqHm7ogEH0=";
    };

    # Package comes with "vendor" directory
    vendorHash = null;
    CGO_ENABLED = "0";

    # https://github.com/openebs/lvm-localpv/blob/c05937b95f53797cfe7500c1e6fe4e3f4687e789/buildscripts/build.sh#L99
    ldflags =
      let
        t = "github.com/openebs/lvm-localpv/pkg/version";
      in
      [
        "-s"
        "-w"
        "-X ${t}.GitCommit=${src.rev}"
        "-X ${t}.Version=v${version}"
        "-X ${t}.VersionMeta=''"
        "-X main.CtlName='lvm-driver'"
      ];

    subPackages = [ "cmd" ];

    postInstall = ''
      mv $out/bin/cmd $out/bin/${binary}
    '';
  };

in
dockerTools.build {
  name = package.pname;
  tag = package.version;

  extraCommands = ''
    mkdir -p ./usr/local/bin
    cp ${package}/bin/${binary} ./usr/local/bin/${binary}
  '';

  config = {
    Entrypoint = [ "/usr/local/bin/${binary}" ];
    ExposedPorts."7676/tcp" = { };

    Env = [
      "PATH=/usr/local/bin:${lib.makeBinPath (with pkgs; [
          lvm2 util-linux
          btrfs-progs xfsprogs e2fsprogs
      ])}"

      # "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };

  passthru = {
    inherit (package) src;
  };

  meta = with lib; {
    description = "OpenEBS LocalPV controller";
    replacementImage = "docker.io/openebs/lvm-driver";
    replacementImageUrl = "https://github.com/openebs/lvm-localpv/blob/lvm-localpv-1.0.1/buildscripts/lvm-driver/Dockerfile";

    license = licenses.asl20;
    platform = platforms.x86_64;
  };
}
