{ dockerTools
, pkgs
, lib
, haproxy
, haproxy-ingress
, bash
, iana-etc
, coreutils
, socat
, dumb-init
, cacert
}:

dockerTools.buildWithUsers {
  name = "haproxy-ingress";
  tag = haproxy-ingress.version;

  users = {
    users.haproxy = {
      name = "haproxy";
      uid = 99;
      group = "haproxy";
      home = "/var/lib/haproxy";
      extraDirectories = [
        "/etc/haproxy"
        "/var/run/haproxy"
      ];
    };
    groups.haproxy = {
      name = "haproxy";
      gid = 99;
      members = [ "haproxy" ];
    };
  };

  fakeRootCommands = ''
    mkdir -p ./var/empty
    chmod 0 ./var/empty

    mkdir -p ./tmp
    chmod 1777 ./tmp

    # This is very important because the controller can share
    # directories with another container running another image
    # so we can't use this in "contents" because it will be processed
    # via "symlinkJoin" from "streamLayeredImage"
    cp  -r ${haproxy-ingress.rootfs}/. .
    chmod -R ug+w ./etc/haproxy ./etc/lua
  '';

  contents = [
    iana-etc
    dockerTools.binSh
    dockerTools.usrBinEnv

    (pkgs.buildEnv {
      name = "container-env";
      extraPrefix = "/run/system";
      paths = [
        bash
        coreutils
        socat
        dumb-init

        haproxy
      ];
    })
  ];

  config = {
    Entrypoint = [ "/start.sh" ];
    Cmd = [ ];

    User = "haproxy:haproxy";
    StopSignal = "SIGTERM";
    Env = [
      "PATH=/bin:/run/system/bin"
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
