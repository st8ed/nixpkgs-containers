{ dockerTools, makeNgSystem }:

let
  system = makeNgSystem "nixng-hydra" ({ pkgs, config, ... }:
    {
      config = {
        dumb-init = {
          enable = true;
          type.services = { };
        };
        nix = {
          loadNixDb = true;
          persistNix = "/nix-persist";
          config = {
            experimental-features = [ "nix-command" "flakes" ];
            sandbox = true;
            trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
            substituters = [ "https://cache.nixos.org/" ];
          };
        };
        services.hydra = {
          enable = true;
          hydraURL = "http://localhost:3000/";
          notificationSender = "root@example.org";
          useSubstitutes = true;
        };
        services.postgresql.package = pkgs.postgresql_12;
        services.socklog = {
          enable = true;
          unix = "/dev/log";
        };
      };
    });
in
dockerTools.build {
  name = "hydra";
  tag = system.config.services.hydra.package.version;

  config = {
    StopSignal = "SIGCONT";
    Entrypoint =
      [
        "${system.config.system.build.toplevel}/init"
      ];
  };
}
