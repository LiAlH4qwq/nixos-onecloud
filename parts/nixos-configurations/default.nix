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
      # Build host: the flake is evaluated & built on x86_64-linux; the target
      # (armv7l) is selected via nixpkgs.crossSystem in the configuration.
      system = "x86_64-linux";
      specialArgs.flakeConfig = config;
      modules = [
        (root + /nixos-configurations/nixos-onecloud)
      ];
    };
  };
}
