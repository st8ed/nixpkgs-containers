pkgs: super:
let
  inherit (pkgs) lib;

  helmTemplate = with pkgs; stdenv.mkDerivation {
    name = "helm-chart-template";
    version = kubernetes-helm.version;

    buildInputs = [ kubernetes-helm gnused ];

    unpackPhase = ''
      helm create nix-chart
    '';

    patches = [ ./chart.patch ];

    buildPhase = ''
      find ./nix-chart -type f -exec \
          sed -i 's/nix-chart/@CHART_NAME@/g' {} +
    '';

    installPhase = ''
      mv nix-chart $out
    '';
  };

  base = { config, ... }: {
    options = with lib; let
      imageType = types.submodule ({
        options.repository = mkOption { type = types.str; };
        options.tag = mkOption { type = types.str; };
        options.package = mkOption { type = types.nullOr types.path; };
        config.repository = mkDefault config.image.package.imageName;
        config.tag = mkDefault config.image.package.imageTag;
        config.package = mkDefault null;
      });
    in
    {
      name = mkOption {
        type = types.str;
      };

      description = mkOption {
        type = types.str;
        default = "";
      };

      version = mkOption {
        type = types.str;
        default = "0.1.0";
      };

      appVersion = mkOption {
        type = types.str;
      };

      kind = mkOption {
        type = types.enum [ "Deployment" "StatefulSet" "DaemonSet" ];
        default = "Deployment";
      };

      image = mkOption {
        type = imageType;
        default = { };
      };

      images = mkOption {
        type = types.attrsOf imageType;
        default = { };
      };

      extraValues = mkOption {
        type = with types; nullOr lines;
        default = null;
      };

      configMaps = mkOption {
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            prefixedName = mkOption { type = types.bool; default = true; };
            secret = mkEnableOption "";

            data = mkOption { type = with types; attrsOf lines; default = { }; };
            dataTemplate = mkOption { type = with types; nullOr lines; default = null; };

            source = mkOption {
              type = types.str;
              readOnly = true;
              default = ''
                apiVersion: v1
                kind: ${if config.secret then "Secret" else "ConfigMap"}
                metadata:
                  name: ${optionalString config.prefixedName "{{ include \"@CHART_NAME@.fullname\" . }}-"}${name}
                  labels:
                    {{- include "@CHART_NAME@.labels" . | nindent 4 }}
                ${if config.secret then "type: Opaque\nstringData:" else "data:"}
              '' +
              (concatMapStringsSep "\n"
                (x:
                  "  ${x.name}: ${builtins.toJSON x.value}"
                )
                (builtins.attrValues (mapAttrs nameValuePair config.data)))
              + (optionalString (config.dataTemplate != null) config.dataTemplate);
            };
          };
        }));
        default = { };
      };

      containers = mkOption {
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            init = mkOption { type = types.bool; default = false; };
            image = mkOption { type = types.nullOr types.str; default = null; };
            ports = mkOption { type = types.anything; default = { }; };
            volumeMounts = mkOption { type = types.anything; default = { }; };

            extraConfig = mkOption {
              type = types.lines;
              default = "";
            };

            source = mkOption {
              type = types.str;
              readOnly = true;
              default =
                let
                  ports =
                    if ((builtins.attrNames config.ports) != [ ]) then ''
                      ports:
                      ${lib.concatMapStringsSep "\n" (p:
                      "  - name: ${p.name}\n" +
                      "    containerPort: ${toString p.value.port}\n" +
                      "    protocol: ${p.value.protocol}\n"
                      ) (mapAttrsToList lib.nameValuePair config.ports)}'' else "";

                  volumeMounts =
                    if ((builtins.attrNames config.volumeMounts) != [ ]) then ''
                      volumeMounts:
                      ${lib.concatMapStringsSep "\n" (p:
                      "  - name: ${p.name}\n" +
                      "    mountPath: ${toString p.value}\n"
                      ) (mapAttrsToList lib.nameValuePair config.volumeMounts)}'' else "";
                in
                let
                  image =
                    if (config.image == null) then
                      "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
                    else
                      "{{ .Values.images.${config.image}.repository }}:{{ .Values.images.${config.image}.tag }}";

                in
                ''
                  {{- define "@CHART_NAME@.container-${name}" -}}
                  name: ${name}
                  image: "${image}"
                  imagePullPolicy: {{ .Values.image.pullPolicy }}
                  ${ports}${volumeMounts}${config.extraConfig}
                  securityContext:
                    {{- toYaml .Values.securityContext | nindent 12 }}
                  resources:
                    {{- toYaml .Values.resources | nindent 12 }}
                  {{- end }}
                '';
            };
          };
        }));
        default = { };
      };

      volumes = mkOption {
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            spec = mkOption { type = types.str; };

            source = mkOption {
              type = types.str;
              readOnly = true;
              default = ''
                {{- define "@CHART_NAME@.volume-${name}" -}}
                name: ${name}
                ${config.spec}
                {{- end }}
              '';
            };
          };
        }));


        default = { };
      };

      servicePorts = mkOption {
        type = types.attrsOf types.anything;
        default = { };
      };

      extraSpec = mkOption {
        type = with types; nullOr lines;
        default = null;
      };

      template = mkOption {
        type = types.package;
        readOnly = true;
        default = helmTemplate;
      };

      chart = mkOption {
        type = types.package;

        readOnly = true;
        default = pkgs.stdenv.mkDerivation {
          pname = "${config.name}-helmchart";
          version = config.version;

          dontUnpack = true;

          buildInputs = with pkgs; [ gnused kubernetes-helm yamllint ];

          buildPhase = ''
            cp -r ${config.template}/. .
            chmod a+rwx templates Chart.yaml

            echo "$CHART_YAML" >Chart.yaml
            echo "$SPEC_YAML" >templates/_spec.yaml

            ${optionalString (length (builtins.attrNames config.configMaps) > 0) ''
            echo "$CMAP_YAML" >templates/configmap.yaml
            ''}

            ${optionalString (config.kind == "StatefulSet") ''
            mv templates/deployment.yaml templates/statefulset.yaml
            sed -i 's|^kind:.*$|kind: StatefulSet|g' templates/statefulset.yaml
            sed -i 's|template:|serviceName: {{ include "@CHART_NAME@.fullname" . }}\n  template:|g' templates/statefulset.yaml
            ''}

            ${optionalString (config.kind == "DaemonSet") ''
            mv templates/deployment.yaml templates/daemonset.yaml
            sed -i 's|^kind:.*$|kind: DaemonSet|g' templates/daemonset.yaml
            sed -i '/^\s*replicas:.*$/d' templates/daemonset.yaml
            ''}

            for f in $(find . -type f); do
                substituteInPlace "$f" \
                    --subst-var CHART_NAME
            done

            ${pkgs.chartTools.patchYaml "values.yaml" config.image.package.manifest {
                ".image.repository" = ''.registry + "/" + .repository''; 
                ".image.tag" = ''.tag + "@" + .digest'';
            }}

            ${concatMapStringsSep "\n" ({ name, value }: pkgs.chartTools.patchYaml "values.yaml"
              value.package.manifest
              {
                ".images.${name}.repository" = ''.registry + "/" + .repository''; 
                ".images.${name}.tag" = ''.tag + "@" + .digest'';
              }
            ) (mapAttrsToList nameValuePair config.images)}

            ${optionalString (config.extraValues != null) ''
            echo ${escapeShellArg config.extraValues} >>values.yaml
            ''}
          '';

          checkPhase = ''
            helm lint .
            helm template . | yamllint -
          '';

          installPhase = ''
            cp -r . $out
          '';

          CHART_NAME = config.name;

          CHART_YAML = ''
            apiVersion: v2
            name: ${config.name}
            description: ${config.description}
            type: application
            version: ${config.version}
            appVersion: "${config.appVersion}"
          '';

          CMAP_YAML = (lib.concatMapStringsSep "\n---\n"
            (x: x.source)
            (builtins.attrValues config.configMaps)
          );

          SPEC_YAML = (lib.concatMapStringsSep "\n"
            (x: x.source)
            (builtins.attrValues config.containers))
          + (lib.concatMapStringsSep "\n"
            (x: x.source)
            (builtins.attrValues config.volumes))
          + (with lib; let
            initContainers = filterAttrs (n: v: (v.init)) config.containers;
            containers = filterAttrs (n: v: (!v.init)) config.containers;
            inherit (config) volumes servicePorts;
          in
          ''
            {{- define "@CHART_NAME@.spec" -}}
            ${optionalString ((builtins.attrNames initContainers) != []) "initContainers:"}
            ${concatMapStringsSep "\n" (name:
            "  - {{ include \"@CHART_NAME@.container-${name}\" . | nindent 4 | trim }}"
            ) (builtins.attrNames initContainers)}
            containers:
            ${concatMapStringsSep "\n" (name:
            "  - {{ include \"@CHART_NAME@.container-${name}\" . | nindent 4 | trim }}"
            ) (builtins.attrNames containers)}
            ${optionalString ((builtins.attrNames volumes) != []) "volumes:"}
            ${concatMapStringsSep "\n" (name:
            "  - {{ include \"@CHART_NAME@.volume-${name}\" . | nindent 4 | trim }}"
            ) (builtins.attrNames volumes)}
            {{- end }}

            {{- define "@CHART_NAME@.servicePorts" -}}
            ${concatMapStringsSep "\n" (item: ''
            - name: ${item.name}
              port: ${toString item.value.port}
              targetPort: ${toString item.value.targetPort}
              protocol: ${item.value.protocol}{{ if eq .Values.service.type "NodePort" }}
              nodePort: ${lib.optionalString (item.value ? nodePort) item.value.nodePort}{{ end }}
            '') (builtins.attrValues (lib.mapAttrs lib.nameValuePair servicePorts))}
            {{- end }}

            {{- define "@CHART_NAME@.extraSpec" -}}
            ${optionalString (config.extraSpec != null) config.extraSpec}
            {{- end }}
          '');
        };
      };
    };
  };

in
{
  chartTools = pkgs.lib.makeScope super.newScope (self: {
    patchYaml = path: src: values: with pkgs.lib; ''
      ${escapeShellArgs [
        "${pkgs.yq-go}/bin/yq"
        "--inplace"

        (''load("${src}") as $src | '' + (concatMapStringsSep " | "
          ({ name, value }: ''${name} = ($src | ${value})'')
          (mapAttrsToList nameValuePair values)
        ))

        path
      ]}
    '';

    buildSimpleChart = module: (lib.evalModules {
      modules = [
        base
        module
      ];
    }).config.chart;
  });
}
