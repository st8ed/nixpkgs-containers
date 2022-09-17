{ chartTools, dockerImages }:

chartTools.buildChart rec {
  name = "bind";
  version = "0.1.2";
  appVersion = "9.18.3";

  kind = "Deployment";
  values.image = {
    repository = "registry.st8ed.com/bind";
    tag = "${appVersion}@sha256:abbe3ace703299e9f6c22f6ecab81cb75315257e10220bc330a04fa86be1eb6d";
  };

  extraValues = ''
    service:
        type: ClusterIP
        port: 53
        nodePort: 32053

    config:
        resolverNetworks: [ "127.0.0.0/24" ]
        blackholeNetworks: [ ]
        forward: only
        forwarders: [ ]

    extraConfig: ""

    keys: ""

    stateVolume: |
      emptyDir: {}

    zones: {}
    #    "hello.test":
    #        type: primary
    #        file: |
    #            $ORIGIN hello.test.
    #        extraOptions: |
    #            allow-query { any; };
    #            update-policy {
    #              grant rndc-key subdomain hello.test. a;
    #            };
  '';

  configMaps."config".secret = true;
  configMaps."config".data = {
    "named.conf" = ''
      acl resolvernetworks { {{ range .Values.config.resolverNetworks }}{{ . }}; {{ end }} };
      acl blockednetworks { {{ range .Values.config.blackholeNetworks }}{{ . }}; {{ end }} };

      options {
          listen-on { 0.0.0.0/0; };

          allow-recursion { resolvernetworks; };
          allow-query-cache { resolvernetworks; };
          allow-query { resolvernetworks; };
          blackhole { blockednetworks; };

          forward {{ .Values.config.forward }};
          forwarders {
            {{- range .Values.config.forwarders }}
            {{ . }};
            {{- end }}
          };

          directory "/var/run/named";
          pid-file "/var/run/named/named.pid";

          dnssec-validation no;
          auth-nxdomain no;
      };

      logging {
          category default { default_stderr; };
      };

      {{ .Values.extraConfig }}

      {{ range $name, $zone := .Values.zones }}
      zone "{{ $name }}" {
          type {{ $zone.type }};
          {{- if $zone.file }}
          file "/var/lib/zones/{{ $name }}.db";
          {{- end }}
          {{- $zone.extraOptions | nindent 4 }}
      };
      {{ end }}
    '';
    "rndc.key" = "{{ .Values.keys }}";
  };

  configMaps."scripts".data."init.sh" = ''
    #!/bin/sh
    cp -LRv /etc/bind/zones/*.db /var/lib/zones/

    chown -Rv 1000:1000 /var/lib/zones
  '';

  configMaps."zones".dataTemplate = ''
    {{ range $name, $zone := .Values.zones }}{{ if $zone.file }} "{{ $name }}.db": |
        {{- $zone.file | nindent 4 }}
    {{ end }}{{- end }}
  '';

  containers."init" = {
    init = true;

    image = "registry.st8ed.com/busybox:1.35.0@sha256:492e32c46e5cbf2ec433a6134768f66603d0b203b4c3cf4430f67628de4903c8";
    volumeMounts = {
      "scripts" = "/scripts";
      "zones" = "/etc/bind/zones";
      "state" = "/var/lib/zones";
    };

    extraConfig = ''
      command: [ "/scripts/init.sh" ]
    '';
  };

  containers."bind" = {
    ports = {
      "dns" = {
        port = 53;
        protocol = "UDP";
      };
      "dns-tcp" = {
        port = 53;
        protocol = "TCP";
      };
    };

    volumeMounts = {
      "config" = "/etc/bind/named.conf.d";
      "state" = "/var/lib/zones";
    };

    extraConfig = ''
      args: [ "-4" ]
    '';
  };

  volumes = {
    "config".spec = ''
      secret:
        secretName: {{ include "@CHART_NAME@.fullname" . }}-config
    '';
    "state".spec = ''
      {{ .Values.stateVolume }}
    '';

    "scripts".spec = ''
      configMap:
        name: {{ include "@CHART_NAME@.fullname" . }}-scripts
        defaultMode: 0777
    '';
    "zones".spec = ''
      configMap:
        name: {{ include "@CHART_NAME@.fullname" . }}-zones
    '';
  };


  servicePorts = {
    "dns" = {
      port = "{{ .Values.service.port }}";
      targetPort = "dns";
      protocol = "UDP";
      nodePort = "{{ .Values.service.nodePort }}";
    };
    "dns-tcp" = {
      port = "{{ .Values.service.port }}";
      targetPort = "dns-tcp";
      protocol = "TCP";
      nodePort = "{{ .Values.service.nodePort }}";
    };
  };
}
