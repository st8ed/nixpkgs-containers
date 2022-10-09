{ pkgs, lib, dockerTools, haproxy, iana-etc, cacert }:

dockerTools.buildWithUsers {
  name = "haproxy";
  tag = haproxy.version;

  users = {
    users.haproxy = {
      name = "haproxy";
      uid = 99;
      group = "haproxy";
      home = "/var/lib/haproxy";
    };
    groups.haproxy = {
      name = "haproxy";
      gid = 99;
      members = [ "haproxy" ];
    };
  };

  contents = [
    haproxy
    iana-etc
    dockerTools.binSh
    dockerTools.usrBinEnv
  ];

  config = {
    Entrypoint = [
      (pkgs.writeScript "haproxy-docker-entrypoint.sh" ''
        #!/bin/sh
        set -e

        # first arg is `-f` or `--some-option`
        if [ "''${1#-}" != "$1" ]; then
            set -- haproxy "$@"
        fi

        if [ "$1" = 'haproxy' ]; then
            shift # "haproxy"
            # if the user wants "haproxy", let's add a couple useful flags
            #   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
            #   -db -- disables background mode
            set -- haproxy -W -db "$@"
        fi

        exec "$@"
      '')
    ];
    Cmd = [ ];

    StopSignal = "SIGUSR1";
    User = "haproxy:haproxy";

    Env = [
      "PATH=/bin"
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };

  meta = with lib; {
    description = "HAProxy TCP/HTTP Load Balancer";
    replacementImage = "library/haproxy";
    replacementImageUrl = "https://github.com/docker-library/haproxy/blob/master/2.7/Dockerfile";

    license = licenses.gpl2;
    platform = platforms.x86_64;
  };
}
