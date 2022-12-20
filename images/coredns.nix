{ lib, dockerTools, coredns, cacert }:

dockerTools.build {
  name = "coredns";
  tag = "v${coredns.version}";

  extraCommands = ''
    cp -r ${coredns}/bin/coredns ./
    mkdir -p ./etc/ssl/certs
    cp ${cacert}/etc/ssl/certs/ca-bundle.crt ./etc/ssl/certs/ca-certificates.crt
  '';

  config = {
    ExposedPorts = {
      "53/tcp" = { };
      "53/udp" = { };
    };
    Entrypoint = [ "/coredns" ];
  };

  meta = with lib; {
    description = "CoreDNS";
    replacementImage = "registry.k8s.io/coredns/coredns";
    replacementImageUrl = "https://github.com/coredns/coredns/blob/055b2c31a9cf28321734e5f71613ea080d216cd3/Dockerfile";

    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
