{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hardware.onecloud;
in
{
  options.hardware.onecloud = {
    enable = mkEnableOption "Xunlong OneCloud (Amlogic S805/Meson8b) support";

    kernelPackage = mkOption {
      type = types.package;
      default = pkgs.onecloud.kernel;
      description = "Kernel package for OneCloud. Defaults to the flake-provided Meson8b kernel via the onecloud overlay.";
    };

    ubootPackage = mkOption {
      type = types.package;
      default = pkgs.onecloud.uboot;
      description = "U-Boot package for OneCloud. Defaults to the flake-provided hzyitc u-boot via the onecloud overlay.";
    };

    bootScrPackage = mkOption {
      type = types.package;
      default = pkgs.onecloud.bootScr;
      description = "Boot script package (boot.scr + splash). Defaults to the flake-provided package via the onecloud overlay.";
    };

    console = mkOption {
      type = types.enum [
        "both"
        "serial"
        "display"
      ];
      default = "both";
      description = ''
        Where the boot log prints:
        - both: HDMI display and serial
        - display: HDMI display only
        - serial: serial console only
      '';
    };

    sdImage = {
      enable = mkEnableOption "SD card image generation for OneCloud";

      firmwarePartitionOffset = mkOption {
        type = types.int;
        default = 16;
        description = "Gap in MiB before the first partition. Matches Armbian OFFSET=16, used for u-boot.";
      };

      firmwareSize = mkOption {
        type = types.int;
        default = 256;
        description = "Size of the FAT boot partition in MiB. Matches Armbian BOOTSIZE=256.";
      };

      compressImage = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to compress the SD image with zstd.";
      };
    };
  };

  config = mkIf cfg.enable {
    # ── Kernel ──────────────────────────────────────────────────────
    boot.kernelPackages = mkDefault (pkgs.linuxPackagesFor cfg.kernelPackage);

    # ── Bootloader ──────────────────────────────────────────────────
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = true;

    # ── Console ─────────────────────────────────────────────────────
    boot.kernelParams = mkMerge [
      (mkIf (cfg.console == "serial" || cfg.console == "both") [
        "console=ttyAML0,115200n8"
      ])
      (mkIf (cfg.console == "display" || cfg.console == "both") [
        "console=tty1"
      ])
      [
        "no_console_suspend"
        "consoleblank=0"
      ]
    ];

    boot.consoleLogLevel = mkDefault 7;

    # ── Device tree ─────────────────────────────────────────────────
    hardware.deviceTree = {
      enable = true;
      name = mkDefault "meson8b-onecloud.dtb";
    };

    # ── Initrd ──────────────────────────────────────────────────────
    # The ancient Amlogic u-boot only understands a gzip-compressed
    # uInitrd, so make sure the initrd is gzip. Matches Armbian's
    # `mkimage -C gzip`.
    boot.initrd.compressor = "gzip";

    # The all-hardware.nix profile pulls in a huge list of x86/enterprise
    # modules that the Meson8b kernel doesn't build. The core drivers
    # (mmc, dwc2, stmmac, ext4) are built-in (=y) in the Armbian config,
    # so the initrd only needs the handful of real modules.
    boot.initrd.includeDefaultModules = mkForce false;
    boot.initrd.availableKernelModules = mkForce [
      "uas"
      "virtio_net"
    ];

    # ── Firmware ────────────────────────────────────────────────────
    hardware.enableRedistributableFirmware = true;

    # ── Network ─────────────────────────────────────────────────────
    networking.useDHCP = mkDefault true;

    # ── 32-bit sysctl fix ───────────────────────────────────────────
    # NixOS writes vm.mmap_rnd_bits into 55-nixos-aslr-entropy.conf, but that
    # knob does not exist on the 32-bit ARM kernel, so systemd-sysctl.service
    # fails ("Apply Kernel Variables"). Neutralize the file.
    environment.etc."sysctl.d/55-nixos-aslr-entropy.conf".text = lib.mkForce ''
      # vm.mmap_rnd_bits is unsupported on 32-bit ARM
    '';

    # Grow-the-root only makes sense when flashing a real eMMC/SD card; on a
    # raw-USB image there is nothing to extend and the service just fails the
    # boot log. Re-enable (drop this line) when flashing the eMMC.
    systemd.services."expand-root-partition".enable = lib.mkForce false;

    # NOTE: a global uutils overlay (diffutils/findutils/coreutils) breaks the
    # systemd-initrd evaluation (`boot.initrd.systemd.users.messagebus.shell`),
    # so it is intentionally NOT applied here.
  };
}
