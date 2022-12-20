{ chartTools, dockerImages }:

let
  inherit (dockerImages) nfs-ganesha socat;

  # Commands to generate self-signed TLS and import it to Kubernetes:
  #
  # openssl req -x509 \
  #    -newkey rsa:4096 -nodes \
  #    -keyout server.private.pem -out server.public.pem \
  #    -sha256 -days 365 \
  #    -subj '/CN=localhost'
  #
  # openssl req -x509 \
  #    -newkey rsa:4096 -nodes \
  #    -keyout client.private.pem -out client.public.pem \
  #    -sha256 -days 365 \
  #    -subj '/CN=localhost'
  #
  # cat server.private.pem server.public.pem > server.pem
  # cat client.private.pem client.public.pem > client.pem
  # cat client.public.pem > ca.pem
  #
  # kubectl create secret generic \
  #    -n gateway nfs-tls \
  #    --from-file=server.pem \
  #    --from-file=ca.pem

in
chartTools.buildSimpleChart rec {
  name = "nfs-ganesha";
  version = "0.1.0";
  appVersion = nfs-ganesha.imageTag;

  kind = "StatefulSet";
  image.package = nfs-ganesha;
  images.socat.package = socat;

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
        # Running privileged is not required
        # privileged: true
        capabilities:
          # TODO: Uncommenting breaks things
          #drop:
          #  - ALL

          # This is required
          add:
            - DAC_READ_SEARCH
    '';
  };

  containers."socat" = {
    image = "socat";

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
