{ pkgs, lib, dockerTools, kubernetes }:

let
  version = kubernetes.version;

  csi-provisioner = pkgs.callPackage ./csi-provisioner.nix { };
  csi-resizer = pkgs.callPackage ./csi-resizer.nix { };
  csi-snapshotter = pkgs.callPackage ./csi-snapshotter.nix { };

  csi-node-driver-registrar = pkgs.callPackage ./csi-node-driver-registrar.nix { };

  mkImage = name: package: binary: dockerTools.build {
    inherit name;
    tag = package.version;

    extraCommands = ''
      cp ${package}/bin/${binary} ./${binary}
    '';

    config = {
      Entrypoint = [ "/${binary}" ];
    };

    meta = with lib; {
      description = "Kubernetes CSI sidecar container";
      replacementImage = "registry.k8s.io/sig-storage/${name}";
      replacementImageUrl = "https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile";

      license = licenses.asl20;
      platform = platforms.x86_64;
    };
  };
in
{
  kube-csi-provisioner = mkImage "kube-csi-provisioner" csi-provisioner "csi-provisioner";
  kube-csi-resizer = mkImage "kube-csi-resizer" csi-resizer "csi-resizer";
  kube-csi-snapshotter = mkImage "kube-csi-snapshotter" csi-snapshotter "csi-snapshotter";
  kube-csi-snapshot-controller = mkImage "kube-csi-snapshot-controller" csi-snapshotter "snapshot-controller";
  kube-csi-snapshot-validation-webhook = mkImage "kube-csi-snapshot-validation-webhook" csi-snapshotter "snapshot-validation-webhook";
  kube-csi-node-driver-registrar = mkImage "kube-csi-node-driver-registrar" csi-node-driver-registrar "csi-node-driver-registrar";
}
