{ pkgs, haproxy, dockerLib, iana-etc, dockerTools }:

# https://github.com/docker-library/haproxy/blob/b429a6f005908205a0635e12a41d957ba87ad8fd/2.3/alpine/Dockerfile
dockerLib.buildWithUsers {
  name = "haproxy";

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
    ];
  };
}
