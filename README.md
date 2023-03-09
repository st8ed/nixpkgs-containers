This repository contains a collection of OCI container images & Helm charts built with Nix.
Most of images mimic specificied replacement images.

| Image  | Drop-in replacement image |
|---|---|
| docker.io/st8ed/bind:9.18.8 |  |
| docker.io/st8ed/busybox:1.35.0 | [docker.io/library/busybox](https://hub.docker.com/_/busybox) |
| docker.io/st8ed/cert-manager-acmesolver:1.11.0 | [quay.io/jetstack/cert-manager-acmesolver](https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.acmesolver) |
| docker.io/st8ed/cert-manager-cainjector:1.11.0 | [quay.io/jetstack/cert-manager-cainjector](https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.cainjector) |
| docker.io/st8ed/cert-manager-controller:1.11.0 | [quay.io/jetstack/cert-manager-controller](https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.controller) |
| docker.io/st8ed/cert-manager-ctl:1.11.0 | [quay.io/jetstack/cert-manager-ctl](https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.ctl) |
| docker.io/st8ed/cert-manager-webhook:1.11.0 | [quay.io/jetstack/cert-manager-webhook](https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.webhook) |
| docker.io/st8ed/coredns:v1.10.0 | [registry.k8s.io/coredns/coredns](https://github.com/coredns/coredns/blob/055b2c31a9cf28321734e5f71613ea080d216cd3/Dockerfile) |
| docker.io/st8ed/curl:7.86.0 |  |
| docker.io/st8ed/docker-registry:2.8.1 | [docker.io/library/registry](https://hub.docker.com/_/registry) |
| docker.io/st8ed/etcd:3.5.5-0 | [registry.k8s.io/etcd/etcd](https://github.com/kubernetes/kubernetes/tree/e98853ec28c7c7e40cb449812a87eda6c8d5aad0/cluster/images/etcd) |
| docker.io/st8ed/flannel:v0.20.1 | [docker.io/flannel/flannel](https://github.com/flannel-io/flannel/blob/8124fc7978e9789efbdc6766580aec6575a9c6ce/images/Dockerfile.amd64) |
| docker.io/st8ed/flannel-cni-plugin:v1.2.0 | [docker.io/flannel/flannel-cni-plugin](https://github.com/flannel-io/cni-plugin/blob/3e8006e5acf061257b53423d4c8d9ff54a8c965b/Dockerfile.amd64) |
| docker.io/st8ed/gitea:1.16.5 | [docker.io/gitea/gitea:latest-rootless](https://github.com/go-gitea/gitea/blob/main/Dockerfile.rootless) |
| docker.io/st8ed/grafana:v9.2.6 | [docker.io/grafana/grafana](https://github.com/grafana/grafana/blob/main/packaging/docker/ubuntu.Dockerfile) |
| docker.io/st8ed/haproxy:2.6.6 | [docker.io/library/haproxy](https://github.com/docker-library/haproxy/blob/master/2.7/Dockerfile) |
| docker.io/st8ed/haproxy-ingress:0.14.2 | [quay.io/jcmoraisjr/haproxy-ingress](https://github.com/jcmoraisjr/haproxy-ingress/blob/master/rootfs/Dockerfile) |
| docker.io/st8ed/k8s-sidecar:v1.18.1 | [docker.io/kiwigrid/k8s-sidecar](https://github.com/kiwigrid/k8s-sidecar/blob/master/Dockerfile) |
| docker.io/st8ed/kube-apiserver:v1.25.4 | [registry.k8s.io/kube-apiserver](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) |
| docker.io/st8ed/kube-controller-manager:v1.25.4 | [registry.k8s.io/kube-controller-manager](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) |
| docker.io/st8ed/kube-csi-node-driver-registrar:2.3.0 | [registry.k8s.io/sig-storage/kube-csi-node-driver-registrar](https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile) |
| docker.io/st8ed/kube-csi-provisioner:3.0.0 | [registry.k8s.io/sig-storage/kube-csi-provisioner](https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile) |
| docker.io/st8ed/kube-csi-resizer:1.2.0 | [registry.k8s.io/sig-storage/kube-csi-resizer](https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile) |
| docker.io/st8ed/kube-csi-snapshot-controller:4.0.0 | [registry.k8s.io/sig-storage/kube-csi-snapshot-controller](https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile) |
| docker.io/st8ed/kube-csi-snapshot-validation-webhook:4.0.0 | [registry.k8s.io/sig-storage/kube-csi-snapshot-validation-webhook](https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile) |
| docker.io/st8ed/kube-csi-snapshotter:4.0.0 | [registry.k8s.io/sig-storage/kube-csi-snapshotter](https://github.com/kubernetes-csi/external-provisioner/blob/master/Dockerfile) |
| docker.io/st8ed/kube-proxy:v1.25.4 | [registry.k8s.io/kube-proxy](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) |
| docker.io/st8ed/kube-scheduler:v1.25.4 | [registry.k8s.io/kube-scheduler](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) |
| docker.io/st8ed/kube-state-metrics:v2.7.0 | [registry.k8s.io/kube-state-metrics/kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/blob/master/Dockerfile) |
| docker.io/st8ed/minio:2022-10-24T18-35-07Z |  |
| docker.io/st8ed/nfs-ganesha:4.1 |  |
| docker.io/st8ed/nix-daemon:2.11.0 |  |
| docker.io/st8ed/openebs-lvm-driver:1.0.1 | [docker.io/openebs/lvm-driver](https://github.com/openebs/lvm-localpv/blob/lvm-localpv-1.0.1/buildscripts/lvm-driver/Dockerfile) |
| docker.io/st8ed/pause:1.25.4 | [registry.k8s.io/pause](https://github.com/kubernetes/kubernetes/blob/5437d493da9435c9a32b244cd8bb12faf88075ae/build/pause/Dockerfile) |
| docker.io/st8ed/postgresql:14.6 |  |
| docker.io/st8ed/prometheus:v2.40.3 | [docker.io/prom/prometheus](https://github.com/prometheus/prometheus/blob/main/Dockerfile) |
| docker.io/st8ed/prometheus-admission-webhook:v0.61.1 | [quay.io/prometheus-operator/admission-webhook](https://github.com/prometheus-operator/prometheus-operator/blob/main/cmd/admission-webhook/Dockerfile) |
| docker.io/st8ed/prometheus-alertmanager:v0.24.0 | [docker.io/prom/alertmanager](https://github.com/prometheus/alertmanager/blob/main/Dockerfile) |
| docker.io/st8ed/prometheus-config-reloader:v0.61.1 | [quay.io/prometheus-operator/prometheus-config-reloader](https://github.com/prometheus-operator/prometheus-operator/blob/main/cmd/prometheus-config-reloader/Dockerfile) |
| docker.io/st8ed/prometheus-operator:v0.61.1 | [quay.io/prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/Dockerfile) |
| docker.io/st8ed/socat:1.7.4.3 |  |
| docker.io/st8ed/transmission:3.00 |  |
