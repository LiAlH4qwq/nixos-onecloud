{
  config,
  inputs,
  lib,
  ...
}:
let
  armv7l = lib.systems.examples.armv7l-hf-multiplatform;
in
{
  flake.nixosConfigurations.onecloud-sdimage = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.flake.nixosModules.nixos-onecloud
      {
        nixpkgs.crossSystem = armv7l;

        hardware.onecloud.enable = true;
        hardware.onecloud.sdImage.enable = true;

        security.sudo-rs.enable = true;

        users.users.nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          password = "nixos";
        };

        system.stateVersion = "26.05";
      }
    ];
    specialArgs.flakeConfig = config;
  };
}
