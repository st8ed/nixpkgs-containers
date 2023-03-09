{ pkgs, lib, dockerTools, postgresql, busybox, iana-etc }:

let
  package = postgresql;

  config = {
    listen_addresses = "*";
    port = 5432;

    hba_file = "${pkgs.writeText "pg_hba.conf" authentication}";
    ident_file = "${pkgs.writeText "pg_ident.conf" identMap}";

    log_destination = "stderr";
  };

  dataDir = "/var/lib/postgresql/${package.psqlSchema}";

  authentication = ''
    host  all all all          scram-sha-256

    local all all              peer
    host  all all 127.0.0.1/32 md5
    host  all all ::1/128      md5
  '';

  identMap = "";

  configFile =
    let
      toStr = with lib; value:
        if true == value then "yes"
        else if false == value then "no"
        else if isString value then "'${lib.replaceStrings ["'"] ["''"] value}'"
        else toString value;
    in
    pkgs.writeTextDir "postgresql.conf" (
      lib.concatStringsSep "\n" (lib.mapAttrsToList
        (
          n: v: "${n} = ${toStr v}"
        )
        config)
    );

  entrypoint = pkgs.writeShellApplication {
    name = "postgresql-entrypoint.sh";
    runtimeInputs = [ package busybox ];
    text = ''
      export PGDATA="${dataDir}"

      if [[ ! -e "$PGDATA/PG_VERSION" ]] ; then
           initdb -U postgres --pwfile=<(echo -n "$POSTGRES_PASSWORD")
           # touch "$PGDATA/.first_startup"
      fi

      ln -sfn "${configFile}/postgresql.conf" "$PGDATA/postgresql.conf"

      exec postgres "$@"
    '';
  };

in
dockerTools.buildWithUsers {
  name = "postgresql";
  tag = package.version;

  users = {
    users.postgres = {
      uid = 71;
      name = "postgres";
      group = "postgres";
      home = dataDir;
    };
    groups.postgres = {
      gid = 71;
      name = "postgres";
      members = [ "postgres" ];
    };
  };

  fakeRootCommands = ''
    install -dm750 -o 71 -g 71 .${dataDir}
    install -dm755 -o 71 -g 71 ./run/postgresql
  '';

  contents = [
    package
    pkgs.bash
    iana-etc
  ];

  config = {
    Entrypoint = [ "${entrypoint}/bin/postgresql-entrypoint.sh" ];
    Cmd = [ ];

    User = "71:71";
    WorkingDir = dataDir;
    Env = [
      "HOME=${dataDir}"
    ];
  };

  meta = with lib; {
    description = "PostgreSQL database";

    # TODO: PostgreSQL license?
    # license = licenses.mpl20;
    platforms = platforms.linux;
  };
}
