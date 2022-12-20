{ dockerTools, makeNgSystem }:

let
  system = makeNgSystem "nixng-nix-daemon" ({ pkgs, config, ... }:
    {
      config = {
        dumb-init = {
          enable = true;
          type.services = { };
        };
        nix = {
          enable = true;
          loadNixDb = true;
          persistNix = "/nix-persist";
          config = {
            experimental-features = [ "nix-command" "flakes" ];
            sandbox = true;
            trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
            substituters = [ "https://cache.nixos.org/" ];
          };

          daemon = true;
        };
      };
    });
in
dockerTools.build {
  name = "nix-daemon";
  tag = system.config.nix.package.version;

  config = {
    StopSignal = "SIGCONT";
    Entrypoint =
      [
        "${system.config.system.build.toplevel}/init"
      ];
  };
}
