{ pkgs, lib, dockerTools, nfs-ganesha }:

let
  entrypoint = pkgs.writeShellApplication {
    name = "ganesha-entrypoint.sh";
    runtimeInputs = with pkgs; [ busybox ];
    text = ''
      cat - <<EOF >/var/run/ganesha/ganesha.conf
      NFS_CORE_PARAM {
          Protocols = 4;
          Bind_addr = 127.0.0.1;

          Enable_NLM = false;
          Enable_RQUOTA = false;

          fsid_device = true;
      }

      #MDCACHE {
          #Entries_HWMark = 100000;
      #}

      NFSv4 {
          Graceless = true;
          RecoveryRoot = "/var/run/ganesha/recovery";
          Only_Numeric_Owners = true;
      }

      EXPORT
      {
          Export_Id = 1;
          Path = /export;
          Pseudo = "/export";

          Protocols = 4;
          Transports = TCP;
          # SecType = none;

          Access_Type = RW;
          Squash = no_root_squash;
          # Disable_ACL = true;

          FSAL {
              Name = VFS;
          }
      }

      LOG {
          Default_Log_Level = INFO;

          Facility {
              name = FILE;
              destination = "/proc/self/fd/1";
              enable = active;
          }
      }
      EOF

      exec /bin/ganesha.nfsd -F -p /var/run/ganesha/ganesha.pid -f /var/run/ganesha/ganesha.conf "$@"
    '';
  };

in
dockerTools.build rec {
  name = "nfs-ganesha";
  tag = nfs-ganesha.version;

  contents = [ nfs-ganesha ];

  fakeRootCommands = ''
    install -dm770 ./var/run/ganesha
    ln -sf /proc/mounts ./etc/mtab
  '';

  config = {
    Entrypoint = [ "${entrypoint}/bin/ganesha-entrypoint.sh" ];
    Cmd = [ ];
    User = "0:0";

    ExposedPorts = {
      "2049/tcp" = { };
    };

    Volumes = {
      "/export" = { };
    };
  };

  meta = with lib; {
    description = "NFS userspace server";

    license = licenses.gpl3;
    platform = platforms.linux;
  };
}
