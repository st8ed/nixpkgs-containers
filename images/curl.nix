{ lib, dockerTools, curl }:

dockerTools.build {
  name = "curl";
  tag = curl.version;

  config = {
    Entrypoint = [ "${curl}/bin/curl" ];
    User = "1000:1000";
  };

  meta = with lib; {
    description = "cURL";

    platforms = platforms.linux;
  };
}
