{ pkgs, lib, dockerTools, transmission, iana-etc }:

let
  package = transmission.override {
    enableSystemd = false;
    installLib = false;
  };

  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" {
    # Ensure Local peer discovery is disabled
    lpd-enabled = false;

    # Disable UPnP and NAT-PMP
    port-forwarding-enabled = false;
    peer-port = 51413;

    # Require encryption
    encryption = 2;

    # RPC settings
    rpc-enabled = true;
    rpc-port = 9091;
  };

  entrypoint = pkgs.writeShellApplication {
    name = "transmission-entrypoint.sh";
    runtimeInputs = with pkgs; [ coreutils jq ];
    text = ''
      if [ -z "$TRANSMISSION_PASSWORD" ]; then
        echo "TRANSMISSION_PASSWORD environment variable is not set!" >&2
        exit 1
      fi

      install -dm750 -o 70 -g 70 /var/lib/transmission/.config/transmission-daemon

      (
        cd /var/lib/transmission/.config/transmission-daemon

        if [ ! -f settings.json ]; then
          cp "${settingsFile}" settings.json
        fi

        jq \
          --slurp                                                           \
          --arg user "''${TRANSMISSION_USER:-admin}"                        \
          --arg password "$TRANSMISSION_PASSWORD"                           \
          '.[0] * .[1] | ."rpc-user" = $user | ."rpc-password" = $password' \
          "${settingsFile}" settings.json                                   \
          >settings.json.new

        mv -f settings.json.new settings.json
      )

      exec /bin/transmission-daemon -f "$@"
    '';
  };

in
dockerTools.buildWithUsers {
  name = "transmission";
  tag = package.version;

  users = {
    users.transmission = {
      name = "transmission";
      uid = 70;
      group = "transmission";
      home = "/var/lib/transmission";
    };
    groups.transmission = {
      name = "transmission";
      gid = 70;
      members = [ "transmission" ];
    };
  };

  fakeRootCommands = ''
    install -dm750 -o 70 -g 70 ./var/lib/transmission
  '';

  contents = [
    package
    iana-etc
  ];

  config = {
    Entrypoint = [ "${entrypoint}/bin/transmission-entrypoint.sh" ];
    Cmd = [ ];

    User = "transmission:transmission";
    WorkingDir = "/var/lib/transmission";
    Env = [
      "HOME=/var/lib/transmission"
    ];
  };
}
