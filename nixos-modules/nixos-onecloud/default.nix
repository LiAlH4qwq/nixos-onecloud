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
    enable = mkEnableOption "XunLei OneCloud (Amlogic S805 / Meson8b) support";

    kernelPackage = mkOption {
      type = types.package;
      default = pkgs.onecloud.kernel;
      description = "Kernel package for XunLei OneCloud. Defaults to the flake-provided Meson8b kernel via the onecloud overlay.";
    };

    ubootPackage = mkOption {
      type = types.package;
      default = pkgs.onecloud.uboot;
      description = "U-Boot package for XunLei OneCloud. Defaults to the flake-provided hzyitc u-boot via the onecloud overlay.";
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
      enable = mkEnableOption "SD card image generation for XunLei OneCloud";

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

      rootSizeMiB = mkOption {
        type = types.int;
        default = 6144;
        description = ''
          Size of the ext4 root filesystem baked into the image, in MiB.

          make-ext4-fs.nix only gives the root ~16 MiB of slack, and the stock
          sd-image relies on grow-root-at-first-boot to make it usable. That
          growth is flaky when the kernel refuses to re-read the partition
          table of a mounted USB/SD (EBUSY), which leaves the root ~full and
          makes first boot fail with ENOSPC (register-nix-paths, systemd-logind
          and dhcpcd all fail). Pre-sizing the filesystem here guarantees
          enough space regardless of whether boot-time growth succeeds.

          Must fit the target media: a 7.28 GiB eMMC leaves ~6.9 GiB for the
          root (16 MiB gap + 256 MiB BOOT), so the default 6144 MiB (6 GiB)
          fits an 8 GB eMMC as well as any larger SD/USB stick.
        '';
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
        # DEBUG: verbose systemd logging. NOTE the XunLei OneCloud boot.scr flow builds
        # its own cmdline and ignores boot.kernelParams, so this only takes
        # effect for the extlinux path; on the boot.scr path the flag is passed
        # via armbianEnv.txt extraargs in sdimage.nix. Remove once the reflash
        # is verified - it slows boot and spams the console.
        "systemd.log_level=debug"
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

    # ── Cross-compile doc workarounds ───────────────────────────────
    # FIXME: host/target build hacks for producing this 32-bit ARM system on
    # an x86_64 host. They belong in the reusable module (not the machine
    # config) so other consumers such as ../nixos-config, which also enable
    # fish and uutils, get them for free. Ideally fix the underlying cross
    # builds (or upstream the flags) and then delete this block.
    # The cross check is done on `prev` inside the overlay (not on `pkgs` in
    # the module) to avoid the `pkgs` <-> `nixpkgs.overlays` recursion.
    nixpkgs.overlays = [
      (final: prev:
        optionalAttrs (prev.stdenv.buildPlatform != prev.stdenv.hostPlatform) {
          # fish 4.x builds its host-side Rust `xtask` helper while generating
          # its docs (`cmake/Docs.cmake`). Under a cross build the pkg-config
          # environment only points at the *target* (armv7l) pcre2, so the
          # x86_64 xtask link fails ("skipping incompatible … libpcre2-8.so").
          # Docs are useless on this board, so drop WITH_DOCS (and the
          # untestable cross test-run).
          fish = prev.fish.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (lib.cmakeBool "WITH_DOCS" false) ];
            doCheck = false;
          });

          # The GNUmakefile's `build-uudoc` (manpages/completions) does a host
          # build of `uudoc` but keeps the cross CC set, so blake3's build script
          # tries to assemble x86-64 SSE code with the armv7 compiler (-m64) and
          # fails. Manpages/completions are pointless on this board already, so
          # skip them. NOTE: this is only a build-flag override, NOT the global
          # uutils `replaceDependencies` overlay, which breaks systemd-initrd
          # evaluation and stays deliberately unapplied.
          uutils-coreutils-noprefix = prev.uutils-coreutils-noprefix.overrideAttrs (old: {
            makeFlags = (old.makeFlags or [ ]) ++ [ "MANPAGES=n" "COMPLETIONS=n" ];
          });
        })
    ];

    # First-boot root growth: handled in sdimage.nix (robustify + the sd-image
    # root is pre-sized via rootSizeMiB, so growth is best-effort only).
  };
}
