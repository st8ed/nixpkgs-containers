{ dockerTools
, lib
, haproxy
, haproxy-ingress
, bash
, iana-etc
, coreutils
, socat
, openssl
, lua5_3
, dumb-init
, cacert
}:

# https://github.com/docker-library/haproxy/blob/b429a6f005908205a0635e12a41d957ba87ad8fd/2.3/alpine/Dockerfile
dockerTools.buildWithUsers {
  name = "haproxy-ingress";
  tag = haproxy-ingress.version;

  users = {
    users.haproxy = {
      name = "haproxy";
      uid = 1001;
      group = "haproxy";
      home = "/var/lib/haproxy";
      extraDirectories = [
        "/etc/haproxy"
        "/var/run/haproxy"
      ];
    };
    groups.haproxy = {
      name = "haproxy";
      gid = 1001;
      members = [ "haproxy" ];
    };
  };

  fakeRootCommands = ''
    mkdir -p ./var/empty
    chmod 0 ./var/empty

    mkdir -p ./tmp
    chmod 1777 /tmp
  '';

  contents = [
    haproxy
    haproxy-ingress
    iana-etc
    dockerTools.binSh
    dockerTools.usrBinEnv
  ];

  config = {
    Entrypoint = [ "/start.sh" ];
    Cmd = [ ];

    StopSignal = "SIGTERM";
    User = "haproxy:haproxy";
    Env = [
      "PATH=${lib.makeBinPath [ bash coreutils socat openssl lua5_3 dumb-init ]}:/bin"
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
