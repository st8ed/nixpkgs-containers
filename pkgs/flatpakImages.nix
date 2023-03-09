pkgs: super: {
  flatpakImages.flatpak-runtime = with pkgs; let
    version = lib.version;

    metadata = writeText "flatpak-metadata" ''
      [Runtime]
      name=${flatpakTools.options.namespace}Platform
      runtime=${flatpakTools.options.namespace}Platform/x86_64/${version}
      sdk=${flatpakTools.options.namespace}Platform/x86_64/${version}
    '';
  in
  runCommand "flatpak-runtime"
    {
      buildInputs = [ flatpak ostree ];
    } ''
    mkdir -p ./build/usr/bin ./build/usr/etc ./build/files

    cp -rf ${pkgsStatic.bashInteractive}/* ./build/usr/
    cp -rf ${pkgsStatic.coreutils}/* ./build/usr/

    cp ${metadata} ./build/metadata

    mkdir -p ./repo
    flatpak build-export \
      --runtime \
      --ostree-verbose --verbose \
      ./repo ./build ${version}

    flatpak build-bundle \
      --runtime \
      --ostree-verbose --verbose \
      ./repo $out ${flatpakTools.options.namespace}Platform ${version}
  '';

  flatpakImages.firefox = pkgs.callPackage ../images/firefox.nix { };
}
