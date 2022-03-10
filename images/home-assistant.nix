{ pkgs
, nixos
, home-assistant
, dockerLib
, bash
, coreutils
, gettext
, gawk
, gnugrep
, findutils
, iputils
}:

dockerLib.buildFromNixos rec {
  name = "home-assistant";

  system = nixos {
    services.home-assistant = {
      enable = true;

      package = (home-assistant.override {
        extraComponents = [
          "api"
          "auth"
          "config"
          "homeassistant"
          "device_automation"
          "feedreader"
          "frontend"
          "http"
          "image"
          "lovelace"
          "persistent_notification"
          "person"
          "system_log"
          "websocket_api"

          "mpd"

          "mqtt"
          "mqtt_room"
          "mqtt_statestream"

          "esphome"

          "recorder"
          "history"
          "logbook"

          "intent_script"
          "notify"

          "zone"
          "scene"
          "device_tracker"
          "ping"
          "proximity"
          "bayesian"
          "command_line"
          "otp"
          "trend"
          "uptime"
          "weather"
          "map"
          "mobile_app"
          "system_health"

          "alert"

          "generic_thermostat"
          "input_boolean"
          "group"
          "input_number"
          "tod"
          "light"
          "device_sun_light_trigger"
        ];
      }).overrideAttrs (oldAttrs: {
        doCheck = false;
        doInstallCheck = false;
      });

      autoExtraComponents = false;

      configWritable = true;
      config = {
        homeassistant = {
          name = "Home";
          unit_system = "metric";
        };
        frontend = {
          themes = "!include_dir_merge_named themes";
        };
      };
    };
  };

  entryService = "home-assistant";

  extraPaths = [
    bash
    coreutils
    gettext # TODO: Do we need these?
    gawk
    gnugrep
    findutils
    iputils # for ping 
  ];

  extraConfig = {
    ExposedPorts = {
      "${toString system.config.services.home-assistant.port}/tcp" = { };
    };
    Volumes = {
      "${system.config.users.users.hass.home}" = { };
    };
  };
}
