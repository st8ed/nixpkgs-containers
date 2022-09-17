{ chartTools, dockerImages }:

let
  image = dockerImages.transmission; # TODO

in
chartTools.buildChart rec {
  name = "transmission";
  version = "0.1.0";
  appVersion = "3.0.0";

  kind = "StatefulSet";
  values.image = {
    repository = "registry.st8ed.com/transmission";
    tag = "${appVersion}@sha256:f01377245e82d7b22f683fcced2f41a5654974b4e95e854de97b772efb1333ac";
  };

  extraValues = ''
    auth:
        username: admin
        password: "secret"
  '';

  configMaps."auth" = {
    secret = true;
    data = {
      username = "{{ .Values.auth.username | quote }}";
      password = "{{ .Values.auth.password | quote }}";
    };
  };

  containers."transmission" = {
    ports = {
      "http" = {
        port = 9091;
        protocol = "TCP";
      };
      "peer-tcp" = {
        port = 51413;
        protocol = "TCP";
      };
      "peer-udp" = {
        port = 51413;
        protocol = "UDP";
      };
    };

    volumeMounts = {
      "downloads" = "/var/lib/transmission";
    };

    extraConfig = ''
      env:
      - name: TRANSMISSION_USERNAME
        valueFrom:
            secretKeyRef:
              name: {{ include "@CHART_NAME@.fullname" . }}-auth
              key: username
      - name: TRANSMISSION_PASSWORD
        valueFrom:
            secretKeyRef:
              name: {{ include "@CHART_NAME@.fullname" . }}-auth
              key: password
    '';
  };

  servicePorts = {
    "http" = {
      port = "{{ .Values.service.port }}";
      targetPort = "http";
      protocol = "TCP";
    };
    "peer-tcp" = {
      port = 51413;
      targetPort = "peer-tcp";
      protocol = "TCP";
    };
    "peer-udp" = {
      port = 51413;
      targetPort = "peer-udp";
      protocol = "UDP";
    };
  };

  extraSpec = ''
    volumeClaimTemplates:
      - metadata:
          name: downloads
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 1Gi
  '';
}
