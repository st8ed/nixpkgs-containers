{ chartTools, dockerImages }:

let
  image = dockerImages.nfs-ganesha;

in
chartTools.buildChart rec {
  name = "nfs-ganesha";
  version = "0.1.0";
  appVersion = "4.0";

  kind = "StatefulSet";
  values.image = {
    repository = "registry.st8ed.com/nfs-ganesha";
    tag = "${appVersion}@sha256:2c7c8a8b92c2f33600d0d25bcb57bad3d94e6cb45760e3d061a3597edce6e74e";
  };

  extraValues = ''
    service:
        type: ClusterIP
        port: 2049
        nodePort: 32049

    certs:
        secretName:
  '';

  containers."nfs-ganesha" = {
    volumeMounts = {
      "export" = "/export";
    };

    extraConfig = ''
      securityContext:
        #privileged: true
        capabilities:
             #drop:
             #  - ALL
             add:
               - DAC_READ_SEARCH
    '';
  };

  containers."socat" = {
    image = "registry.st8ed.com/socat:1.7.4.3@sha256:767706cb606bb9346cb337c9705db8a9ed1f12aec202188157cb83188323b56e";

    ports = {
      "nfs-tls" = {
        port = 8443;
        protocol = "TCP";
      };
    };

    volumeMounts = {
      "certs" = "/certs";
    };

    extraConfig = ''
      args: ["OPENSSL-LISTEN:8443,reuseaddr,pf=ip4,fork,cert=/certs/server.pem,cafile=/certs/ca.pem", "TCP-CONNECT:127.0.0.1:2049"]
    '';
  };

  volumes = {
    "certs".spec = ''
      secret:
        secretName: {{ .Values.certs.secretName }}
    '';
  };

  # openssl req -x509 \
  #    -newkey rsa:4096 -nodes \
  #    -keyout server.private.pem -out server.public.pem \
  #    -sha256 -days 365 \
  #    -subj '/CN=localhost'

  #openssl req -x509 \
  #    -newkey rsa:4096 -nodes \
  #    -keyout client.private.pem -out client.public.pem \
  #    -sha256 -days 365 \
  #    -subj '/CN=localhost'

  #cat server.private.pem server.public.pem > server.pem
  #cat client.private.pem client.public.pem > client.pem
  #cat client.public.pem > ca.pem

  #kubectl create secret generic \
  #    -n gateway nfs-tls \
  #    --from-file=server.pem \
  #    --from-file=ca.pem

  servicePorts = {
    "nfs" = {
      port = "{{ .Values.service.port }}";
      targetPort = "nfs-tls";
      protocol = "TCP";
      nodePort = "{{ .Values.service.nodePort }}";
    };
  };

  extraSpec = ''
    volumeClaimTemplates:
      - metadata:
          name: export
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 1Gi
  '';
}
