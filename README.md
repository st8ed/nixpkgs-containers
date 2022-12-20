| Image  | Replacement image | Description |
|---|---|---|
| st8ed/bind:9.18.8 |  | Domain name server |
| st8ed/busybox:1.35.0 | [library/busybox](https://hub.docker.com/_/busybox) | Static build of busybox |
| st8ed/coredns:v1.10.0 | [registry.k8s.io/coredns/coredns](https://github.com/coredns/coredns/blob/055b2c31a9cf28321734e5f71613ea080d216cd3/Dockerfile) | CoreDNS |
| st8ed/curl:7.86.0 |  | cURL |
| st8ed/docker-registry:2.8.1 | [library/registry](https://hub.docker.com/_/registry) | Registry implementation for storing and distributing Docker images |
| st8ed/etcd:3.5.5-0 | [registry.k8s.io/etcd/etcd](https://github.com/kubernetes/kubernetes/tree/e98853ec28c7c7e40cb449812a87eda6c8d5aad0/cluster/images/etcd) | etcd |
| st8ed/flannel:v0.20.1 | [docker.io/flannel/flannel](https://github.com/flannel-io/flannel/blob/8124fc7978e9789efbdc6766580aec6575a9c6ce/images/Dockerfile.amd64) | Flannel |
| st8ed/gitea:1.16.5 | [gitea/gitea:latest-rootless](https://github.com/go-gitea/gitea/blob/main/Dockerfile.rootless) | A self-hosted Git service |
| st8ed/grafana:v9.2.6 | [grafana/grafana](https://github.com/grafana/grafana/blob/main/packaging/docker/ubuntu.Dockerfile) | Grafana docker image |
| st8ed/haproxy:2.6.6 | [library/haproxy](https://github.com/docker-library/haproxy/blob/master/2.7/Dockerfile) | HAProxy TCP/HTTP Load Balancer |
| st8ed/haproxy-ingress:0.13.9 | [quay.io/jcmoraisjr/haproxy-ingress](https://github.com/jcmoraisjr/haproxy-ingress/blob/master/rootfs/Dockerfile) | HAProxy ingress controller |
| st8ed/k8s-sidecar:v1.18.1 | [kiwigrid/k8s-sidecar](https://github.com/kiwigrid/k8s-sidecar/blob/master/Dockerfile) | Collect configmaps and store them in a path |
| st8ed/kube-apiserver:v1.25.4 | [registry.k8s.io/kube-apiserver](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) | Kubernetes binary package |
| st8ed/kube-controller-manager:v1.25.4 | [registry.k8s.io/kube-controller-manager](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) | Kubernetes binary package |
| st8ed/kube-proxy:v1.25.4 | [registry.k8s.io/kube-proxy](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) | Kubernetes binary package |
| st8ed/kube-scheduler:v1.25.4 | [registry.k8s.io/kube-scheduler](https://github.com/kubernetes/kubernetes/blob/e4c8802407fbaffad126685280e72145d89b125e/build/server-image/Dockerfile) | Kubernetes binary package |
| st8ed/kube-state-metrics:v2.7.0 | [registry.k8s.io/kube-state-metrics/kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/blob/master/Dockerfile) | Generate metrics about Kubernetes objects |
| st8ed/minio:2022-10-24T18-35-07Z |  | MinIO server |
| st8ed/nfs-ganesha:4.1 |  | NFS userspace server |
| st8ed/nix-daemon:2.11.0 |  |  |
| st8ed/pause:1.25.4 | [registry.k8s.io/pause](https://github.com/kubernetes/kubernetes/blob/5437d493da9435c9a32b244cd8bb12faf88075ae/build/pause/Dockerfile) | Pod infra image (sandbox image) for Kubernetes |
| st8ed/postgresql:14.6 |  | PostgreSQL database |
| st8ed/prometheus:v2.40.3 | [prom/prometheus](https://github.com/prometheus/prometheus/blob/main/Dockerfile) | Prometheus |
| st8ed/prometheus-admission-webhook:v0.61.1 | [quay.io/prometheus-operator/admission-webhook](https://github.com/prometheus-operator/prometheus-operator/blob/main/cmd/admission-webhook/Dockerfile) | Prometheus webhook helper |
| st8ed/prometheus-alertmanager:v0.24.0 | [prom/alertmanager](https://github.com/prometheus/alertmanager/blob/main/Dockerfile) | Prometheus Alert Manager |
| st8ed/prometheus-config-reloader:v0.61.1 | [quay.io/prometheus-operator/prometheus-config-reloader](https://github.com/prometheus-operator/prometheus-operator/blob/main/cmd/prometheus-config-reloader/Dockerfile) | Prometheus config reload helper |
| st8ed/prometheus-operator:v0.61.1 | [quay.io/prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/Dockerfile) | Prometheus operator |
| st8ed/socat:1.7.4.3 |  | Static build of socat |
| st8ed/transmission:3.00 |  | Transmission BitTorrent client |
