# SD image configuration for OneCloud.
#
# This module imports nixpkgs' sd-image.nix itself (the consumer does NOT
# need to import it) and configures it to produce a flashable image whose
# structure matches the Armbian onecloud port:
#
#   - 16 MiB gap  (OFFSET=16)  -> u-boot written here (hzyitc mksdcard layout)
#   - 256 MiB FAT32 "BOOT"     (BOOTSIZE=256)
#       boot.scr, boot.bmp, uImage, uInitrd, dtb/meson8b-onecloud.dtb, armbianEnv.txt
#   - ext4 root partition      (full NixOS system closure)
#
# nixpkgsPath is baked in at flake evaluation time (the nixpkgs flake input),
# avoiding the `pkgs.path` import-from-derivation recursion.

{ nixpkgsPath }:
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.onecloud;
  mkimage = "${pkgs.buildPackages.ubootTools}/bin/mkimage";
in
{
  # NOTE: we intentionally do NOT import profiles/base.nix here.  It is the
  # minimal-install-CD profile and pulls efibootmgr/efivar which are marked
  # broken on 32-bit ARM.  Nothing in it is required to boot.
  imports = [
    "${nixpkgsPath}/nixos/modules/installer/sd-card/sd-image.nix"
  ];

  config = mkIf (cfg.enable && cfg.sdImage.enable) {
    sdImage = {
      firmwarePartitionOffset = cfg.sdImage.firmwarePartitionOffset;
      firmwareSize = cfg.sdImage.firmwareSize;
      compressImage = cfg.sdImage.compressImage;
      firmwarePartitionName = "BOOT";

      # Populate the FAT /boot/firmware partition exactly like Armbian:
      #   uImage, uInitrd, dtb/meson8b-onecloud.dtb, boot.scr, boot.bmp, armbianEnv.txt
      populateFirmwareCommands = ''
        # Boot script + splash
        cp ${cfg.bootScrPackage}/boot.scr firmware/boot.scr
        cp ${cfg.bootScrPackage}/bootup.bmp firmware/boot.bmp

        # Kernel zImage -> uImage (LOADADDR=0x00208000, matches Armbian SRC_LOADADDR)
        ${mkimage} -A arm -O linux -T kernel -C none \
          -a 0x00208000 -e 0x00208000 -n "Linux kernel" \
          -d ${cfg.kernelPackage}/zImage firmware/uImage

        # Initrd -> uInitrd (gzip, matches Armbian post-update hook)
        ${mkimage} -A arm -O linux -T ramdisk -C gzip \
          -n "uInitrd" -d ${config.system.build.initialRamdisk}/initrd firmware/uInitrd

        # Device tree
        mkdir -p firmware/dtb
        cp ${cfg.kernelPackage}/dtbs/meson8b-onecloud.dtb firmware/dtb/meson8b-onecloud.dtb

        # Environment file consumed by boot.scr.
        #
        # `rootdev=fstab` => kernel cmdline `root=fstab`: with the systemd
        # initrd this tells systemd-fstab-generator to derive sysroot from the
        # fstab `/` entry (`/dev/disk/by-label/NIXOS_SD`, x-initrd.mount) only.
        # Passing `root=<device>` here would make the generator ALSO emit a
        # sysroot.mount from the raw root= value, colliding with the fstab one
        # ("Duplicate entry ... sysroot.mount" + generator exit 1). Mounting by
        # label keeps it bootable from a USB stick OR eMMC regardless of the
        # block-device node (sda* / mmcblk*p).
        #
        # `init=` names the stage-2 init: unlike grub/extlinux, the Armbian
        # boot.scr does not pass it, so stage-1 would otherwise fall back to
        # /init on the root and fail with "stage 2 init script not found".
        cat >firmware/armbianEnv.txt <<'ENVEOF'
verbosity=1
bootlogo=false
console=both
rootdev=fstab
rootfstype=ext4
extraargs=init=${config.system.build.toplevel}/init
ENVEOF
      '';

      # Populate /boot on the ext4 root with NixOS' extlinux layout
      # (harmless with the boot.scr flow, useful with a modern u-boot).
      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} -d ./files/boot
      '';

      # Write u-boot to the SD card exactly like hzyitc's mksdcard:
      #   dd if=u-boot.bin bs=1 count=442           -> sector 0 (bootstrap)
      #   dd if=u-boot.bin bs=512 skip=1 seek=1      -> rest, from sector 1
      # The first 442 bytes overlap the MBR area but leave bytes 442-511
      # (partition table) intact.
      postBuildCommands = ''
        dd if=${cfg.ubootPackage}/u-boot.bin of=$img bs=1 count=442 conv=notrunc
        dd if=${cfg.ubootPackage}/u-boot.bin of=$img bs=512 skip=1 seek=1 conv=notrunc
      '';
    };
  };
}
