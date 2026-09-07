{
  fetchurl,
  lib,
  linuxManualConfig,
  stdenv,
  ...
}:

let
  version = "6.12.28";

  kernelSrc = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz";
    hash = "sha256-6KCZGCVirs/3gd5yznaUYecG2Xr0LXQN/yDrRQ3Vdx4=";
  };

  # Armbian meson kernel config, with NixOS-required additions appended.
  # linuxManualConfig uses the configfile verbatim (kernelPatches.extraConfig
  # is only honored by buildLinux), so we add the missing option here.
  kernelConfig = stdenv.mkDerivation {
    inherit version;
    pname = "linux-meson-onecloud.config";

    src = fetchurl {
      url = "https://raw.githubusercontent.com/armbian/build/main/config/kernel/linux-meson-current.config";
      hash = "sha256-9PGEGOfDSZpfmW8d9uGSOdffFxYP0IFytASIpBrvHas=";
    };

    dontUnpack = true;

    installPhase = ''
      cat "$src" > "$out"
      # NixOS sysctl.nix requires this to generate vm.mmap_rnd_bits.
      # (CONFIG_ARCH_MMAP_RND_COMPAT_BITS_MAX is only needed when building
      # the NixOS system for a 64-bit host, which we don't target.)
      echo "CONFIG_ARCH_MMAP_RND_BITS_MAX=32" >> "$out"

      # Armbian's meson-current config does not enable the kernel lockup /
      # hung-task detectors. Without them a boot-time driver hang gives no
      # backtrace (watchdog_thresh / hung_task_timeout_secs boot params are
      # ignored). Turn them on so the ~23s OneCloud boot freeze prints a
      # "Call trace" / "INFO: task ... blocked" identifying the wedged driver.
      # These all `depends on DEBUG_KERNEL`, which Armbian leaves off — enable
      # it first or olddefconfig silently drops the detectors.
      echo "CONFIG_DEBUG_KERNEL=y" >> "$out"
      echo "CONFIG_DETECT_HUNG_TASK=y" >> "$out"
      echo "CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=30" >> "$out"
      echo "CONFIG_SOFTLOCKUP_DETECTOR=y" >> "$out"
      echo "CONFIG_LOCKUP_DETECTOR=y" >> "$out"
      echo "CONFIG_HARDLOCKUP_DETECTOR=y" >> "$out"

      # NixOS 26.05 mounts /etc from an erofs metadata image in the initrd
      # (rw-etc: /run/nixos-etc-metadata). Without EROFS that mount fails and
      # the boot drops to emergency mode. Make it built-in so it works in the
      # initrd without module loading.
      echo "CONFIG_EROFS_FS=y" >> "$out"
      echo "CONFIG_EROFS_FS_ZIP=y" >> "$out"

      # rw-etc then overlays the metadata image onto /sysroot/etc for a
      # writable /etc; that needs overlayfs built-in too.
      echo "CONFIG_OVERLAY_FS=y" >> "$out"
    '';
  };

  # All meson8b patches from Armbian
  mesonPatches = import ./patches { inherit fetchurl; };

in
linuxManualConfig {
  inherit version;

  src = kernelSrc;

  configfile = kernelConfig;

  # Allow import-from-derivation so the build system can read the config
  # to determine isModular (CONFIG_MODULES=y) and other config-dependent settings.
  # This is required because configfile is a derivation, not a local path.
  allowImportFromDerivation = true;

  # Apply all Armbian meson patches as kernel patches
  kernelPatches = map (p: {
    name = baseNameOf p;
    patch = p;
  }) mesonPatches;

  extraMeta = {
    description = "Linux kernel for Onecloud (Amlogic S805 / Meson8b)";
    license = lib.licenses.gpl2Only;
    platforms = [ "armv7l-linux" ];
  };
}
