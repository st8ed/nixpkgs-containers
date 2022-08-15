{ pkgs, lib, bash, coreutils, dockerTools, grafana, makeWrapper, gnugrep, gnused, cacert, iana-etc }:

let
  entrypoint = pkgs.writeScriptBin "grafana-entrypoint.sh" ''
    #!/usr/bin/env bash
    set -ex

    PERMISSIONS_OK=0

    if [ ! -r "$GF_PATHS_CONFIG" ]; then
        echo "GF_PATHS_CONFIG='$GF_PATHS_CONFIG' is not readable."
        PERMISSIONS_OK=1
    fi

    if [ ! -w "$GF_PATHS_DATA" ]; then
        echo "GF_PATHS_DATA='$GF_PATHS_DATA' is not writable."
        PERMISSIONS_OK=1
    fi

    if [ ! -r "$GF_PATHS_HOME" ]; then
        echo "GF_PATHS_HOME='$GF_PATHS_HOME' is not readable."
        PERMISSIONS_OK=1
    fi

    if [ $PERMISSIONS_OK -eq 1 ]; then
        echo "You may have issues with file permissions, more information here: http://docs.grafana.org/installation/docker/#migrate-to-v51-or-later"
    fi

    if [ ! -d "$GF_PATHS_PLUGINS" ]; then
        mkdir "$GF_PATHS_PLUGINS"
    fi

    if [ ! -z ''${GF_AWS_PROFILES+x} ]; then
        > "$GF_PATHS_HOME/.aws/credentials"

        for profile in ''${GF_AWS_PROFILES}; do
            access_key_varname="GF_AWS_''${profile}_ACCESS_KEY_ID"
            secret_key_varname="GF_AWS_''${profile}_SECRET_ACCESS_KEY"
            region_varname="GF_AWS_''${profile}_REGION"

            if [ ! -z "''${!access_key_varname}" -a ! -z "''${!secret_key_varname}" ]; then
                echo "[''${profile}]" >> "$GF_PATHS_HOME/.aws/credentials"
                echo "aws_access_key_id = ''${!access_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
                echo "aws_secret_access_key = ''${!secret_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
                if [ ! -z "''${!region_varname}" ]; then
                    echo "region = ''${!region_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
                fi
            fi
        done

        chmod 600 "$GF_PATHS_HOME/.aws/credentials"
    fi

    # Convert all environment variables with names ending in __FILE into the content of
    # the file that they point at and use the name without the trailing __FILE.
    # This can be used to carry in Docker secrets.
    for VAR_NAME in $(env | grep '^GF_[^=]\+__FILE=.\+' | sed -r "s/([^=]*)__FILE=.*/\1/g"); do
        VAR_NAME_FILE="$VAR_NAME"__FILE
        if [ "''${!VAR_NAME}" ]; then
            echo >&2 "ERROR: Both $VAR_NAME and $VAR_NAME_FILE are set (but are exclusive)"
            exit 1
        fi
        echo "Getting secret $VAR_NAME from ''${!VAR_NAME_FILE}"
        export "$VAR_NAME"="$(< "''${!VAR_NAME_FILE}")"
        unset "$VAR_NAME_FILE"
    done

    export HOME="$GF_PATHS_HOME"

    if [ ! -z "''${GF_INSTALL_PLUGINS}" ]; then
      OLDIFS=$IFS
      IFS=','
      for plugin in ''${GF_INSTALL_PLUGINS}; do
        IFS=$OLDIFS
        if [[ $plugin =~ .*\;.* ]]; then
            pluginUrl=$(echo "$plugin" | cut -d';' -f 1)
            pluginInstallFolder=$(echo "$plugin" | cut -d';' -f 2)
            grafana-cli --pluginUrl ''${pluginUrl} --pluginsDir "''${GF_PATHS_PLUGINS}" plugins install "''${pluginInstallFolder}"
        else
            grafana-cli --pluginsDir "''${GF_PATHS_PLUGINS}" plugins install ''${plugin}
        fi
      done
    fi

    exec grafana-server                           \
      --homepath="$GF_PATHS_HOME"                               \
      --config="$GF_PATHS_CONFIG"                               \
      --packaging=docker                                        \
      "$@"                                                      \
      cfg:default.log.mode="console"                            \
      cfg:default.paths.data="$GF_PATHS_DATA"                   \
      cfg:default.paths.logs="$GF_PATHS_LOGS"                   \
      cfg:default.paths.plugins="$GF_PATHS_PLUGINS"             \
      cfg:default.paths.provisioning="$GF_PATHS_PROVISIONING"
  '';

in
dockerTools.buildWithUsers rec {
  name = "grafana";
  tag = grafana.version;

  contents = [
    dockerTools.binSh
    dockerTools.usrBinEnv
    iana-etc

    (pkgs.buildEnv {
      name = "grafana-env";
      extraPrefix = "/run/system";
      paths = [
        grafana
        entrypoint

        bash
        coreutils
        gnugrep
        gnused

        cacert
      ];
    })
  ];

  users = {
    users.grafana = {
      uid = 472;
      name = "grafana";
      group = "grafana";
      home = "/home/grafana";
    };
    groups.grafana = {
      gid = 472;
      name = "grafana";
      members = [ "grafana" ];
    };
  };

  fakeRootCommands = ''
    install -dm770 -o 472 -g 472 ./etc/grafana
    install -dm770 -o 472 -g 472 ./var/log/grafana
    install -dm770 -o 472 -g 472 ./var/lib/grafana 
  '';

  config = {
    Entrypoint = [ "grafana-entrypoint.sh" ];
    Cmd = [ ];
    User = "grafana:grafana";
    WorkingDir = "/home/grafana";

    Env = [
      "PATH=/usr/local/bin:/run/system/bin:/bin"
      "SSL_CERT_FILE=/run/system/etc/ssl/certs/ca-bundle.crt"

      "GF_PATHS_CONFIG=/etc/grafana/grafana.ini"
      "GF_PATHS_DATA=/var/lib/grafana"
      "GF_PATHS_HOME=${grafana}/share/grafana"
      "GF_PATHS_LOGS=/var/log/grafana"
      "GF_PATHS_PLUGINS=/var/lib/grafana/plugins"
      "GF_PATHS_PROVISIONING=/etc/grafana/provisioning"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };

  meta = with lib; {
    description = "Grafana docker image";
    replacementImage = "grafana/grafana";
    replacementImageUrl = "https://github.com/grafana/grafana/blob/main/packaging/docker/ubuntu.Dockerfile";

    license = licenses.agpl3;
    platform = platforms.x86_64;
  };
}

