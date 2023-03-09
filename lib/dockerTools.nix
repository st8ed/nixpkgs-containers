pkgs: super: {
  dockerTools = pkgs.lib.makeScope super.newScope (self: super.dockerTools // {
    options = pkgs.lib.makeScope super.newScope (self: {
      repositoryPrefix = "";
      registry = "";
    });

    buildCompressedImage = name: stream: pkgs.runCommandNoCC "${name}.oci.tar"
      {
        buildInputs = with pkgs; [ skopeo moreutils jq nukeReferences gnutar ];
        outputs = [ "out" "manifest" ];

        # allowedReferences = [ ];
      } ''
      # Piping archive stream to skopeo isn't working correctly
      ${stream} > archive.tar

      mkdir -p ./tmp ./image

      # TODO: Find another way to remove runtime dependencies
      # nuke-refs archive.tar

      skopeo --insecure-policy copy \
        --all \
        --tmpdir ./tmp \
        --digestfile=./digestfile \
        "docker-archive:./archive.tar" \
        oci:./image:"${stream.imageName}:${stream.imageTag}"

      # Reproducibly build image
      tar --sort=name \
        --mtime="@0" \
        --owner=0 --group=0 --numeric-owner \
        -cf $out -C ./image .

      jq \
        --null-input \
        --rawfile digest ./digestfile \
          ' .registry = "${self.options.registry}"
          | .repository = "${stream.imageName}"
          | .tag = "${stream.imageTag}"
          | .digest = $digest
          | ."oci-archive" = "'$out'"' \
      > $manifest
    '';

    build = { tag, meta ? { }, ... } @ args_:
      let
        args = (builtins.removeAttrs args_ [ "meta" ]) // {
          name = "${self.options.repositoryPrefix}${args_.name}";
          inherit tag;
        };

        compressedImage = with pkgs.dockerTools; buildCompressedImage "${args_.name}-${args.tag}" (streamLayeredImage args);

        stream = with pkgs.dockerTools; streamLayeredImage args;
        streamDebug = with pkgs.dockerTools; streamLayeredImage ({ includeStorePaths = false; } // args);

        package = compressedImage.overrideAttrs (oldAttrs: {
          inherit meta;
          passthru = {
            imageName = args.name;
            imageShortName = args_.name;
            imageTag = args.tag;

            imageReference = "${args.name}:${args.tag}";

            inherit stream streamDebug;

            testLocal = pkgs.writeScriptBin "container-shell" ''
              set -eou pipefail
              set -x
              export PATH=/run/current-system/sw/bin

              podman load -i ${package} && podman run \
                --rm -it \
                "$@" \
                ${args.name}:${args.tag}
            '';

            devShell =
              let
                entrypoint = pkgs.writeScript "container-shell-entrypoint" ''
                  #!${pkgs.runtimeShell}
                  export PATH=$PATH:${pkgs.coreutils}/bin

                  echo "Original entrypoint: "${pkgs.lib.escapeShellArg args.config.Entrypoint}

                  exec ${pkgs.bashInteractive}/bin/bash
                '';
              in
              pkgs.writeScriptBin "container-shell" ''
                set -eou pipefail
                set -x
                export PATH=/run/current-system/sw/bin

                ${streamDebug} | podman load && podman run \
                  --rm -it \
                  --entrypoint ${entrypoint} \
                  --volume /nix/store:/nix/store:ro \
                  "$@" \
                  ${args.name}:${args.tag}
              '';
          } // (stream.passthru);
        });

      in
      package;

    buildWithUsers = { users, ... } @ args: self.build ((builtins.removeAttrs args [ "users" ]) // {
      fakeRootCommands =
        let
          userList = with builtins; filter (v: v.name != "root" && users.groups."${v.group}".gid != null) (attrValues users.users);
          groupList = with builtins; filter (v: v.name != "root") (attrValues users.groups);
        in
        with pkgs; ''
          mkdir -p ./etc

          echo -n >./etc/shadow ${lib.escapeShellArg ''
            root:!x:::::::
            ${lib.concatMapStrings (user: ''
            ${user.name}:!:::::::
            '') userList}
          ''}
          chmod 644 ./etc/shadow

          echo -n >./etc/passwd ${lib.escapeShellArg ''
            root:x:0:0::/root:/bin/sh
            ${lib.concatMapStrings (user: ''
            ${user.name}:x:${toString user.uid}:${toString users.groups."${user.group}".gid}::${user.home}:
            '') userList}
          ''}
          chmod 644 ./etc/passwd

          echo -n >./etc/group ${lib.escapeShellArg ''
            root:x:0:
            ${lib.concatMapStrings (group: ''
            ${group.name}:x:${toString group.gid}:${builtins.concatStringsSep "," group.members}
            '') groupList}
          ''}
          chmod 644 ./etc/group

          echo -n >./etc/gshadow ${lib.escapeShellArg ''
            root:x::
            ${lib.concatMapStrings (group: ''
            ${group.name}:x::
            '') groupList}
          ''}
          chmod 644 ./etc/gshadow

            ${pkgs.lib.concatMapStrings (user: ''
              install -dm770 \
                  -o ${toString user.uid} -g ${toString users.groups."${user.group}".gid} \
                  .${user.home}
              ${if (user ? extraDirectories) then pkgs.lib.concatMapStrings (path: ''
               install -dm775 \
                  -o ${toString user.uid} -g ${toString users.groups."${user.group}".gid} \
                  .${path}
              '') user.extraDirectories else ""}
          '') (builtins.filter (u: (
                u.name != "root" && builtins.stringLength u.home > 0 && u.home != "/var/empty"
            )) (builtins.attrValues users.users))}
        '' + (if args ? fakeRootCommands then args.fakeRootCommands else "");
    });

    buildFromNixos = { name, tag, system, entryService, extraConfig ? { }, extraPaths ? [ ], fakeRootCommands ? "", meta ? { } }:
      let
        service = system.config.systemd.services.${entryService};
      in
      self.buildWithUsers {
        inherit name tag;

        contents = with pkgs; [
          iana-etc
          self.binSh
          self.usrBinEnv
        ];

        inherit (system.config) users;

        inherit fakeRootCommands meta;

        config = with pkgs; lib.recursiveUpdate
          {
            Entrypoint = [
              (writeScript "${name}-docker-entrypoint.sh" ''
                #!${runtimeShell}
                set -x
                ${if service.serviceConfig ? ExecStartPre then lib.concatStrings service.serviceConfig.ExecStartPre else ""}
                exec ${service.serviceConfig.ExecStart} "$@"
              '')
            ];

            Env = [
              "PATH=${lib.makeBinPath extraPaths}:/bin"
              "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
            ];

            User = lib.optionalString (service.serviceConfig ? User) "${toString 
                  system.config.users.users."${service.serviceConfig.User}".uid
              }:${toString 
                  system.config.users.groups."${service.serviceConfig.User}".gid
              }";

            WorkingDir = with pkgs; lib.optionalString (service.serviceConfig ? WorkingDirectory)
              service.serviceConfig.WorkingDirectory;
          }
          extraConfig;
      };
  });
}
