{ pkgs, lib, gitea, dockerLib, bash, coreutils, gettext, gawk, gnugrep, findutils, cacert, iana-etc, dockerTools }:

let
  rootfs = pkgs.callPackage ./contents.nix {
    package = gitea.override {
      pamSupport = false;
    };
  };

in
dockerLib.buildWithUsers {
  name = "gitea";

  users = {
    users.git = {
      name = "git";
      uid = 1000;
      group = "git";
      home = "/var/lib/gitea/git";
      extraDirectories = [
        "/var/lib/gitea"
        "/etc/gitea"
        "/tmp/gitea"
      ];
    };
    groups.git = {
      name = "git";
      gid = 1000;
      members = [ "git" ];
    };
  };

  contents = [
    rootfs
    iana-etc
    dockerTools.binSh
    dockerTools.usrBinEnv
  ];

  fakeRootCommands = ''
    chmod 1777 ./tmp
  '';

  config = {
    Entrypoint = [ "/usr/local/bin/docker-entrypoint.sh" ];
    Cmd = [ ];

    User = "git:git";
    WorkingDir = "/var/lib/gitea";

    Env = [
      # These utilities are necessary for Helm chart
      "PATH=/usr/local/bin:${lib.makeBinPath [ 
            bash coreutils gettext gawk gnugrep findutils
        ]}"

      "GITEA_WORK_DIR=/var/lib/gitea"
      "GITEA_CUSTOM=/var/lib/gitea/custom"
      "GITEA_TEMP=/tmp/gitea"
      "TMPDIR=/tmp/gitea"
      "GITEA_APP_INI=/etc/gitea/app.ini"
      "HOME=/var/lib/gitea/git"

      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];

    ExposedPorts = {
      "2222/tcp" = { };
      "3000/tcp" = { };
    };

    Volumes = { "/var/lib/gitea" = { }; "/etc/gitea" = { }; };
  };
}
