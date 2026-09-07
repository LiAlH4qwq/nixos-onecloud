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
    nixos-onecloud =
      { ... }:
      {
        # Inject `pkgs.onecloud.*` (kernel/uboot/bootScr) into the NixOS pkgs.
        # `config` here is the flake-parts config, which owns the overlay.
        nixpkgs.overlays = [ config.flake.overlays.nixos-onecloud ];

        imports = [
          (root + /nixos-modules/nixos-onecloud/default.nix)
          (import (root + /nixos-modules/nixos-onecloud/sdimage.nix) { inherit nixpkgsPath; })
        ];
      };
  };
}
