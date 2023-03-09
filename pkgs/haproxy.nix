{ pkgs, haproxy, haproxy-ingress }:

(haproxy.override ({
  useLua = true;
})).overrideAttrs (oldAttrs: {
  inherit (haproxy-ingress) propagatedBuildInputs;

  postFixup = ''
    wrapLuaPrograms
  '';
})
