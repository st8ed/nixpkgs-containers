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

  meta = with lib; {
    description = "HAProxy ingress controller";
    replacementImage = "quay.io/jcmoraisjr/haproxy-ingress";
    replacementImageUrl = "https://github.com/jcmoraisjr/haproxy-ingress/blob/master/rootfs/Dockerfile";

    license = licenses.asl20;
    platform = platforms.linux;
  };
}
