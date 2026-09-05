{ inputs, root, ... }:
let
  onecloud = import (root + /overlays) { inherit inputs root; };
in
{
  flake.overlays.nixos-onecloud = onecloud.overlay;
  flake.overlays.default = onecloud.overlay;
}
