pkgs: super: {
  flatpakTools = pkgs.lib.makeScope super.newScope (self: {
    options = pkgs.lib.makeScope super.newScope (self: {
      namepace = "localhost.";
    });

    build = { name, branch ? pkgs.lib.version, buildCommands ? "", buildOptions }: with pkgs; let
      runtime = "${self.options.namespace}Platform/x86_64/${lib.version}";
      metadata = pkgs.writeText "flatpak-metadata" ''
        [Application]
        name=${self.options.namespace}${name}
        runtime=${runtime}
        sdk=${runtime}
      '';
    in
    runCommand "flatpak-app"
      {
        buildInputs = [ flatpak ostree ];
      } ''
      mkdir -p ./build/var ./build/files
      cp ${metadata} ./build/metadata

      (
        cd ./build/files
        ${buildCommands}
      )

      flatpak build-finish \
        -vv \
        ${lib.concatStringsSep " " buildOptions} \
        ./build

      mkdir -p ./repo
      flatpak build-export \
        --verbose \
        ./repo ./build ${branch}

      flatpak build-bundle \
        --verbose \
        ./repo $out ${self.options.namespace}${name} ${branch}
    '';
  });

}
