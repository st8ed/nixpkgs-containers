{ chartTools, dockerImages }:

let
  inherit (dockerImages) postgresql;

in
chartTools.buildSimpleChart rec {
  name = "postgresql";
  version = "0.1.0";
  appVersion = postgresql.imageTag;

  kind = "StatefulSet";
  image.package = postgresql;

  extraValues = ''
    auth:
      password: "secret"

    service:
      type: ClusterIP
      port: 5432
      externalTrafficPolicy:
  '';

  configMaps."auth" = {
    secret = true;
    data = {
      password = "{{ .Values.auth.password }}";
    };
  };

  containers."postgresql" = {
    ports = {
      "psql" = {
        port = 5432;
        protocol = "TCP";
      };
    };

    volumeMounts = {
      "dbdata" = "/var/lib/postgresql";
    };

    extraConfig = ''
      env:
      - name: POSTGRES_PASSWORD
        valueFrom:
            secretKeyRef:
              name: {{ include "@CHART_NAME@.fullname" . }}-auth
              key: password
    '';
  };

  servicePorts = {
    "psql" = {
      port = "{{ .Values.service.port }}";
      targetPort = "psql";
      protocol = "TCP";
    };
  };

  extraSpec = ''
    volumeClaimTemplates:
      - metadata:
          name: dbdata
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 128Mi
  '';
}
