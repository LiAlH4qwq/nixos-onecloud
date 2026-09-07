{
  config,
  inputs,
  root,
  ...
}:
{
  flake.nixosConfigurations = {
    default = config.flake.nixosConfigurations.nixos-onecloud;
    nixos-onecloud = inputs.nixpkgs.lib.nixosSystem {
      specialArgs.flakeConfig = config;
      modules = [
        (root + /nixos-configurations/nixos-onecloud)
      ];
    };
  };
}
