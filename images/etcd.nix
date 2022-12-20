{ lib, dockerTools, etcd_3_5 }:

# TODO: Add Kubernetes migration script! 

let
  etcd = etcd_3_5;

in
dockerTools.build {
  name = "etcd";
  tag = "${etcd.version}-0";

  extraCommands = ''
    mkdir -p ./bin
      
    cp ${etcd}/bin/etcd ./bin/
    cp ${etcd}/bin/etcdctl ./bin/
  '';

  config = {
    User = "0";
    ExposedPorts = {
      "2379/tcp" = { };
      "2380/tcp" = { };
      "4001/tcp" = { };
      "7001/tcp" = { };
    };
    WorkingDir = "/";
    Env = [ "PATH=/bin" ];
    Entrypoint = [ ];
  };

  meta = with lib; {
    description = "etcd";
    replacementImage = "registry.k8s.io/etcd/etcd";
    replacementImageUrl = "https://github.com/kubernetes/kubernetes/tree/e98853ec28c7c7e40cb449812a87eda6c8d5aad0/cluster/images/etcd";

    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
