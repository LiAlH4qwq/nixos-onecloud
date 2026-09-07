{
  config,
  inputs,
  root,
  ...
}:
let
  nixpkgsPath = "${inputs.nixpkgs}";
in
{
  flake.nixosModules = {
    default = config.flake.nixosModules.nixos-onecloud;
    nixos-onecloud.imports = [
      (root + /modules/nixos-onecloud/default.nix)
      (import (root + /modules/nixos-onecloud/sdimage.nix) { inherit nixpkgsPath; })
    ];
  };
}
