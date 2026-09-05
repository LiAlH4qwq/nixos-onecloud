# Own packages, built once at flake-eval time, and the overlay that injects
# them into a consumer's pkgs under `pkgs.onecloud.*`.
#
# The derivations live flat under ./packages/<name>/default.nix. Each is
# cross/i686/native as needed; the overlay itself is arch-independent because
# it only closes over already-built derivations.
{
  inputs,
  root,
}:
let
  np = inputs.nixpkgs.legacyPackages.x86_64-linux;
  i686 = np.pkgsi686Linux;
  armv7l = np.pkgsCross.armv7l-hf-multiplatform;

  amlimg = np.callPackage (root + /packages/amlimg) { };
  boot-scr = np.callPackage (root + /packages/boot-scr) { };
  kernel = armv7l.callPackage (root + /packages/kernel) { };
  toolchain-bin = i686.callPackage (root + /packages/toolchain-bin) { };
  uboot = np.callPackage (root + /packages/uboot) { toolchain = toolchain-bin; };
in
{
  inherit
    amlimg
    boot-scr
    kernel
    toolchain-bin
    uboot
    ;

  # `pkgs.onecloud.{kernel,uboot,bootScr}` as consumed by the NixOS modules.
  overlay = final: prev: {
    onecloud = {
      bootScr = boot-scr;
      inherit
        kernel
        uboot
        ;
    };
  };
}
