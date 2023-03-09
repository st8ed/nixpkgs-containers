pkgs: super: {
  kustomizePackages.flannel = pkgs.kustomizeTools.build {
    pname = "flannel";
    version = pkgs.flannel.version;

    kustomization = {
      namespace = "kube-networking";

      resources = with pkgs; [
        (runCommand "flannel.yaml"
          {
            inherit (flannel) src;
            buildInputs = [ gnused ];
          } ''
          cp $src/Documentation/kube-flannel.yml kube-flannel.yaml

          sed -i 's/app:\s*\(flannel\)$/app.kubernetes.io\/name: \1/' kube-flannel.yaml
          sed -i '/tier:\s*\(node\)$/d' kube-flannel.yaml

          mv kube-flannel.yaml $out
        '')
      ];

      transformers = with pkgs; [
        (kustomizeTransformers.images {
          # TODO: This is for new version:
          #"docker.io/flannel/flannel" =
          #  dockerImages.flannel;
          #"docker.io/flannel/flannel-cni-plugin" =
          #  dockerImages.flannel-cni-plugin;
          "docker.io/rancher/mirrored-flannelcni-flannel" =
            dockerImages.flannel;
          "docker.io/rancher/mirrored-flannelcni-flannel-cni-plugin" =
            dockerImages.flannel-cni-plugin;
        })
      ];
    };
  };

  kustomizePackages.openebs-localpv = with pkgs; kustomizeTools.build {
    pname = "openebs-localpv";
    version = lib.removePrefix "v" dockerImages.openebs-lvm-driver.imageTag;

    kustomization = rec {
      namespace = "kube-storage";

      resources = [
        "${dockerImages.openebs-lvm-driver.src}/deploy/lvm-operator.yaml"
      ];

      transformers = [
        (kustomizeTransformers.images {
          "k8s.gcr.io/sig-storage/csi-provisioner" =
            dockerImages.kube-csi-provisioner;
          "k8s.gcr.io/sig-storage/csi-resizer" =
            dockerImages.kube-csi-resizer;
          "k8s.gcr.io/sig-storage/csi-snapshotter" =
            dockerImages.kube-csi-snapshotter;
          "k8s.gcr.io/sig-storage/snapshot-controller" =
            dockerImages.kube-csi-snapshot-controller;
          "k8s.gcr.io/sig-storage/csi-node-driver-registrar" =
            dockerImages.kube-csi-node-driver-registrar;

          "openebs/lvm-driver" =
            dockerImages.openebs-lvm-driver;
        })
      ];

      patches = [
        # Patch namespace
        {
          patch = builtins.toJSON [
            {
              op = "test";
              path = "/spec/template/spec/containers/4/env/2/name";
              value = "LVM_NAMESPACE";
            }
            {
              op = "replace";
              path = "/spec/template/spec/containers/4/env/2/value";
              value = namespace;
            }
          ];
          target = {
            kind = "StatefulSet";
            name = "openebs-lvm-controller";
          };
        }

        # Disable analytics
        {
          patch = builtins.toJSON [
            {
              op = "test";
              path = "/spec/template/spec/containers/4/env/4/name";
              value = "OPENEBS_IO_ENABLE_ANALYTICS";
            }
            {
              op = "replace";
              path = "/spec/template/spec/containers/4/env/4/value";
              value = "false";
            }
          ];

          target = {
            kind = "StatefulSet";
            name = "openebs-lvm-controller";
          };
        }
      ];
    };
  };
}
