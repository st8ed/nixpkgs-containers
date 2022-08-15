{ pkgs, lib, dockerTools, transmission, iana-etc }:

let
  package = transmission.override {
    enableSystemd = false;
    installLib = false;
  };

  settings = {
    bind-address-ipv4 = "0.0.0.0";
    bind-address-ipv6 = "::";

    port-forwarding-enabled = false; # Disable UPnP and NAT-PMP
    peer-port = 51413;
    lpd-enabled = false; # Ensure Local peer discovery is disabled

    # Require encryption
    encryption = 2;

    # RPC settings
    rpc-enabled = true;
    rpc-authentication-required = true;
    rpc-bind-address = "0.0.0.0";
    rpc-port = 9091;
    rpc-url = "/";

    rpc-host-whitelist-enabled = false; # TODO: Allow specifying whitelists
    rpc-whitelist-enabled = false;
  };
  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" settings;

  # TODO: Merge updated settings if file already exists
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
          --arg username "''${TRANSMISSION_USERNAME:-admin}"                        \
          --arg password "$TRANSMISSION_PASSWORD"                           \
          '.[0] * .[1] | ."rpc-username" = $username | ."rpc-password" = $password' \
          "${settingsFile}" settings.json                                   \
          >settings.json.new

        mv -f settings.json.new settings.json
      )

      exec /bin/transmission-daemon -f -g /var/lib/transmission/.config/transmission-daemon "$@"
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
    install -dm1777 ./tmp
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
    ExposedPorts = {
      "${toString settings.rpc-port}/tcp" = { };
      "${toString settings.peer-port}/tcp" = { };
      "${toString settings.peer-port}/udp" = { };
    };
  };

  meta = with lib; {
    description = "Transmission BitTorrent client";

    license = with licenses; [ gpl2 gpl3 mit ];
    platform = platforms.linux;
  };
}
