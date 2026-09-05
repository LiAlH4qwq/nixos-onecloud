{ inputs, root, ... }:
let
  onecloud = import (root + /overlays) { inherit inputs root; };
in
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          onecloud.amlimg
          onecloud.toolchain-bin
          pkgs.dosfstools
          pkgs.e2fsprogs
          pkgs.imagemagick
          pkgs.mtools
          pkgs.parted
          pkgs.ubootTools
          pkgs.util-linux
        ];
      };
    };
}
