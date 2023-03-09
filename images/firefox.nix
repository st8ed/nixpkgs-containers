{ pkgs, lib, firefox, profile ? "default", coreutils, nssTools, gnugrep, p11-kit, glibcLocalesUtf8, flatpakTools }:

let
  launcher = with lib; pkgs.writeShellApplication {
    name = "firefox-launcher-${profile}";
    runtimeInputs = with pkgs; [
      firefox
      nssTools
      gnugrep
    ];
    text = ''
      profile_dir=$(echo ~/.mozilla/firefox/*.${escapeShellArg profile})
      p11_library_path_valid=${p11-kit}/lib/pkcs11/p11-kit-client.so

      if [ ! -d "$profile_dir" ]; then
        firefox \
          -CreateProfile ${escapeShellArg profile}

        profile_dir=$(echo ~/.mozilla/firefox/*.${escapeShellArg profile})
        modutil -dbdir "$profile_dir" -create -force
      fi

      p11_library_path=$(
        modutil -dbdir "$profile_dir" -list \
          | grep -Eo "/.*lib/pkcs11/p11-kit-client.so" \
          || true
      )

      if [ "$p11_library_path" != "$p11_library_path_valid" ]; then
        if [ -n "$p11_library_path" ]; then
          modutil -dbdir "$profile_dir" -delete "p11-kit-client" -force
        fi

        modutil -dbdir "$profile_dir" \
          -add "p11-kit-client" \
          -libfile "$p11_library_path_valid" \
          -force
      fi

      exec firefox -P ${escapeShellArg profile}
    '';
  };

  firefox-base64 = data: ''$( echo -n "${data}" | ${coreutils}/bin/base64 | tr "+/=-" "_" )'';

in
flatpakTools.build {
  name = "Firefox" + (
    lib.optionalString (profile != "default") ".${profile}"
  );

  buildOptions = [
    "--require-version=0.11.1"

    "--filesystem=/nix/store:ro"
    "--filesystem=xdg-download:rw"
    "--persist=.mozilla"

    # https://searchfox.org/mozilla-central/source/taskcluster/docker/firefox-flatpak/runme.sh

    #"--share=ipc"
    "--share=network"

    "--socket=pulseaudio"
    "--socket=wayland"
    #"--socket=x11"
    #"--socket=pcsc"
    #"--socket=cups"

    "--device=dri"
    # "--device=all"

    "--talk-name=org.freedesktop.FileManager1"
    "--talk-name=org.a11y.Bus"
    "--talk-name=org.freedesktop.ScreenSaver"
    "--talk-name=org.freedesktop.Notifications"
    #"--talk-name=org.gnome.SessionManager"
    #"--talk-name=\"org.gtk.vfs.*\""
    #"--system-talk-name=org.freedesktop.NetworkManager"

    "--own-name=org.mozilla.firefox.${firefox-base64 profile}"
    #"--own-name=\"org.mpris.MediaPlayer2.firefox.*\""
    # See https://bugzilla.mozilla.org/show_bug.cgi?id=1666084

    #"--env=P11_KIT_DEBUG=all"
    "--env=GTK_USE_PORTAL=1"
    "--env=LOCALE_ARCHIVE=${glibcLocalesUtf8}/lib/locale/locale-archive"
    "--env=FONTCONFIG_PATH=/nix/store/n1b8ljsj0mdjh65yfjgd4qsn8a5jzfwz-fontconfig-etc/etc/fonts"

    "--command=${launcher}/bin/firefox-launcher-${profile}"
  ];
}
