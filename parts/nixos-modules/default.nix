{ config, inputs, root, ... }:
let
  nixpkgsPath = "${inputs.nixpkgs}";
in
{
  flake.nixosModules.nixos-onecloud =
    { ... }:
    {
      nixpkgs.overlays = [ config.flake.overlays.nixos-onecloud ];

      imports = [
        (root + /modules/onecloud/default.nix)
        (import (root + /modules/onecloud/sdimage.nix) { inherit nixpkgsPath; })
      ];
    };

  flake.nixosModules.default = config.flake.nixosModules.nixos-onecloud;
}
