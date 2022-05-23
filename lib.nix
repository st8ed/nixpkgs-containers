pkgs: super: {
  dockerTools = pkgs.lib.makeScope super.newScope (self: super.dockerTools // {
    options = pkgs.lib.makeScope super.newScope (self: {
      rev = "latest";
      enableStreaming = true;
      includeStorePaths = true;
    });

    build = { tag ? self.options.rev, withNixDb ? false, ... } @ args_:
      let
        args = (builtins.removeAttrs args_ [ "withNixDb" ]) // {
          inherit tag;
        };
      in
      with pkgs.dockerTools;
      if withNixDb
      then
        buildLayeredImageWithNixDb args
      else
        (
          if self.options.enableStreaming
          then streamLayeredImage ({ includeStorePaths = self.options.includeStorePaths; } // args)
          else buildLayeredImage args
        );

    buildWithUsers = { users, ... } @ args: self.build ((builtins.removeAttrs args [ "users" ]) // {
      contents = (self.shadowSetup users) ++ (if args ? contents then args.contents else [ ]);

      fakeRootCommands = ''
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

    buildFromNixos = { name, system, entryService, extraConfig ? { }, extraPaths ? [ ], fakeRootCommands ? "" }:
      let
        service = system.config.systemd.services.${entryService};
      in
      self.buildWithUsers {
        inherit name;

        contents = with pkgs; [
          iana-etc
          self.binSh
          self.usrBinEnv
        ];

        inherit (system.config) users;

        inherit fakeRootCommands;

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

    shadowSetup = config:
      let
        userList = with builtins; filter (v: v.name != "root" && config.groups."${v.group}".gid != null) (attrValues config.users);
        groupList = with builtins; filter (v: v.name != "root") (attrValues config.groups);
      in
      with pkgs; [
        (writeTextDir "etc/shadow" ''
          root:!x:::::::
          ${lib.concatMapStrings (user: ''
          ${user.name}:!:::::::
          '') userList}''
        )
        (writeTextDir "etc/passwd" ''
          root:x:0:0::/root:/bin/sh
          ${lib.concatMapStrings (user: ''
          ${user.name}:x:${toString user.uid}:${toString config.groups."${user.group}".gid}::${user.home}:
          '') userList}''
        )
        (writeTextDir "etc/group" ''
          root:x:0:
          ${lib.concatMapStrings (group: ''
          ${group.name}:x:${toString group.gid}:${builtins.concatStringsSep "," group.members}
          '') groupList}''
        )
        (writeTextDir "etc/gshadow" ''
          root:x::
          ${lib.concatMapStrings (group: ''
          ${group.name}:x::
          '') groupList}''
        )
      ];
  });
}
