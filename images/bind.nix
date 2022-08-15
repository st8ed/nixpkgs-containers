{ pkgs, lib, dockerTools, bind, busybox, iana-etc }:

let
  package = bind.override {
    enableGSSAPI = false;
  };
  configFile = pkgs.writeText "named.conf" ''
    include "/etc/bind/named.conf.d/*.key";
    include "/etc/bind/named.conf.d/*.conf";
  '';

  entrypoint = pkgs.writeShellApplication {
    name = "bind-entrypoint.sh";
    runtimeInputs = [ busybox ];
    text = ''
      set -ex
      cp -f ${configFile} /etc/bind/named.conf

      /bin/named-checkconf -c /etc/bind/named.conf
      exec /bin/named -u named -c /etc/bind/named.conf -f "$@"
    '';
  };

in
dockerTools.buildWithUsers {
  name = "bind";
  tag = package.version;

  users = {
    users.named = {
      name = "named";
      uid = 1000;
      group = "named";
      home = "/var/run/named";
    };
    groups.named = {
      name = "named";
      gid = 1000;
      members = [ "named" ];
    };
  };

  fakeRootCommands = ''
    install -dm755 -o 1000 -g 1000 ./etc/bind
    install -dm755 -o 1000 -g 1000 ./etc/bind/named.conf.d
    install -dm750 -o 1000 -g 1000 ./var/run/named

    install -dm1777 ./tmp
  '';

  contents = [
    package
    iana-etc
  ];

  config = {
    Entrypoint = [ "${entrypoint}/bin/bind-entrypoint.sh" ];
    Cmd = [ ];

    User = "root:named";
    WorkingDir = "/var/run/named";
    Env = [
      "HOME=/var/run/named"
    ];
  };

  #  inherit (package) meta;
}
