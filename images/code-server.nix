{ pkgs, lib, dockerTools, code-server, nixUnstable, bashInteractive, coreutils, gitMinimal, procps, openssh, iana-etc, cacert }:

# TODO: Run OpenSSH server in background

let
  workDir = "/home/coder";
in
dockerTools.buildWithUsers rec {
  name = "code-server";
  tag = code-server.version;

  withNixDb = true;

  contents = [
    dockerTools.binSh
    dockerTools.usrBinEnv
    iana-etc

    (pkgs.buildEnv {
      name = "code-server-env";
      extraPrefix = "/run/system";
      paths = [
        code-server

        nixUnstable

        bashInteractive
        coreutils
        gitMinimal
        procps
        openssh

        cacert
      ];
    })
  ];

  users = {
    users.developer = {
      uid = 1000;
      name = "developer";
      group = "developer";
      home = workDir;
    };
    groups.developer = {
      gid = 1000;
      name = "developer";
      members = [ "developer" ];
    };
  };

  fakeRootCommands = ''
    mkdir -p ./tmp
    chmod 1777 ./tmp

    mkdir -m 0755 ./etc/nix
    echo 'sandbox = false' >> ./etc/nix/nix.conf
    echo 'experimental-features = nix-command flakes' >> ./etc/nix/nix.conf
  '';

  config = {
    Entrypoint = [
      "code-server"
      "--bind-addr"
      "0.0.0.0:8080"
      "."
    ];
    Cmd = [
      "--disable-telemetry"
      "--disable-update-check"
    ];
    User = "developer:developer";
    WorkingDir = workDir;
    Env = [
      "PATH=/usr/local/bin:${workDir}/.nix-profile/bin:/run/system/bin:/bin"
      "SSL_CERT_FILE=/run/system/etc/ssl/certs/ca-bundle.crt"

      "SHELL=/run/system/bin/bash"

      # Required by nix
      "NIX_PAGER=/run/system/bin/cat"
      "USER=developer"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };

  meta = with lib; {
    description = "VS Code in the browser with Nix";
    replacementImage = "codercom/code-server";
    replacementImageUrl = "https://github.com/coder/code-server/blob/main/ci/release-image/Dockerfile";

    license = licenses.mit;
    platforms = platforms.x86_64;
  };
}
