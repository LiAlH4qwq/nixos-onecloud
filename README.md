# nixos-onecloud

NixOS port for the **XunLei OneCloud (Amlogic S805 / Meson8b)** — a cheap
NAS-style board from Xunlei (迅雷 / "Thunder"): 4× Cortex-A5, 1 GiB RAM, 8 GiB
eMMC, Gigabit Ethernet. This flake cross-compiles, from `x86_64-linux`, a
complete, flashable NixOS image that boots through the same `u-boot` layout as
Armbian's `onecloud` port.

## Status

The SD/USB image boots NixOS 26.05 on `armv7l`. First-boot store registration,
`systemd-logind` and DHCP are operational now that the root filesystem is
pre-sized instead of relying on (flaky) boot-time growth — see
["Why the root is pre-sized"](#why-the-root-is-pre-sized).

> NOTE: the boot currently appends `systemd.log_level=debug` (both in
> `boot.kernelParams` for the extlinux path and in `armbianEnv.txt`
> `extraargs` for the boot.scr path) to verify the reflash. Remove it once
> confirmed working — it slows boot and spams the console.

## Hardware / boot details

- **SoC:** Amlogic S805 (Meson8b), 32-bit ARM (`armv7l`, hard-float)
- **Console:** HDMI (`tty1`) and/or UART `ttyAML0` @ 115200 8N1 (`console=both`)
- **Boot flow:** Amlogic u-boot → `boot.scr` (FAT `/BOOT`) → `uImage` +
  `uInitrd` + `meson8b-onecloud.dtb` → NixOS systemd initrd
- **Kernel:** 6.12.28, Armbian `linux-meson-current` config + Armbian Meson8b
  patches + XunLei OneCloud DTS, with NixOS-required options appended (see
  `packages/kernel/default.nix`)

The `boot.scr` assembles the kernel command line itself
(`root=<rootdev> rootwait rw <consoleargs> <extraargs>`), so **NixOS
`boot.kernelParams` are ignored** on this boot path. Anything that must reach
the cmdline (console, debug flags, …) has to be set via `armbianEnv.txt` in
`nixos-modules/nixos-onecloud/sdimage.nix`.

## Quick start

Build the SD/USB image (long: builds the cross kernel + full system):

```console
$ nix build .#nixosConfigurations.nixos-onecloud.config.system.build.sdImage
$ ls -lh result/
```

Flash to a USB stick or SD card **≥ ~6.5 GiB** (the root is pre-sized to
6 GiB by default). Identify the device with `lsblk`, then:

```console
$ sudo dd if=result/*.img of=/dev/sdX bs=4M conv=fsync status=progress
```

Insert into the XunLei OneCloud and boot:

- **USB:** `setenv bootdev "usb 0"; usb start`
- **eMMC:** `setenv bootdev "mmc 1"` (from the u-boot prompt, or persist via
  `saveenv`; see `packages/boot-scr/default.nix`)
- **SD:** `setenv bootdev "mmc 0"`

First boot: the image grows the root partition onto the rest of the media when
the kernel allows it (best-effort; never fatal). Login with `nixos`/`nixos`
(`root`/`nixos` also works). Users are immutable (`mutableUsers = false`), so
accounts are declared in `nixos-configurations/`.

## Image layout

Matches the Armbian `onecloud` layout:

| Offset | Size | Contents |
| --- | --- | --- |
| 0 | 16 MiB gap | `u-boot.bin` (first 442 B + from sector 1, hzyitc mksdcard style) |
| 16 MiB | 256 MiB FAT32 `BOOT` | `boot.scr`, `boot.bmp`, `uImage`, `uInitrd`, `dtb/meson8b-onecloud.dtb`, `armbianEnv.txt` |
| 272 MiB | `rootSizeMiB` (default 6144) ext4 | full NixOS system, label `NIXOS_SD` |

Root is mounted **by label** (`root=fstab`), so the same image boots from USB
or eMMC regardless of the block-device node.

## Why the root is pre-sized

`make-ext4-fs.nix` creates the root filesystem at ~its contents + 16 MiB of
slack. The stock sd-image expects a *grow-root-on-first-boot* service
(`expand-root-partition`) to make it usable, but that growth is unreliable when
the kernel refuses to re-read the partition table of a mounted USB/SD
(`EBUSY`). Left un-grown, first boot runs out of space and `ENOSPC`-bricks
itself:

- `register-nix-paths` can't build the Nix store DB
- `systemd-logind` / `dhcpcd` can't create their `StateDirectory` in `/var/lib`
- login fails with `System error` (logind is down)

Mitigation in this flake:

1. `hardware.onecloud.sdImage.rootSizeMiB` (default `6144`) pre-sizes the root
   filesystem at build time, so there is always enough space (fits an 8 GiB
   eMMC: 7.28 GiB − 16 MiB gap − 256 MiB BOOT ≈ 6.9 GiB).
2. `expand-root-partition` is overridden in `sdimage.nix` to be robust and
   quiet: it uses `lsblk … PARTN` (the upstream script's `MAJ:MIN` math breaks
   on `sdb*`/`mmcblk*p`), tolerates `EBUSY`, and never fails the boot. When the
   kernel does accept the new partition size it still grows the root to fill
   the media.

## Repo structure

```
flake.nix                        inputs + flake-parts glue
flake.lock
parts/                           flake-parts modules that define the flake outputs
  default.nix
  overlays/                      flake.overlays.{default,nixos-onecloud}
  nixos-modules/                 flake.nixosModules.{default,nixos-onecloud}
  nixos-configurations/          flake.nixosConfigurations.{default,nixos-onecloud}
  dev-shells/                    devShells.default (build/flash tooling)
overlays/default.nix             builds the own packages once, exposes pkgs.onecloud.*
packages/
  kernel/                        Meson8b kernel (Armbian config + patches)   [armv7l]
  uboot/                         hzyitc U-Boot for XunLei OneCloud           [x86_64]
  boot-scr/                      boot.scr + splash (Armbian-derived)          [x86_64]
  amlimg/                        Amlogic image packing / USB burn tool        [x86_64]
  toolchain-bin/                 gcc-linaro arm-none-eabi 4.8 needed by u-boot [i686]
nixos-modules/
  nixos-onecloud/
    default.nix                  hardware.onecloud NixOS module (options + config)
    sdimage.nix                  sd-image integration (layout, boot files, grow)
nixos-configurations/
  nixos-onecloud/default.nix     the XunLei OneCloud machine definition (cross + users + features)
```

### Flake outputs

- `nixosConfigurations.default` → alias of `nixos-onecloud`
- `nixosConfigurations.nixos-onecloud` → cross-compiled NixOS config (build its
  image via `config.system.build.sdImage`)
- `nixosModules.default` / `nixos-onecloud` → the `hardware.onecloud` module
  (injects `pkgs.onecloud.*` via the overlay)
- `overlays.default` / `nixos-onecloud` → overlay providing
  `pkgs.onecloud.{kernel,uboot,bootScr}`
- `devShells.default` → shell with `amlimg`, `ubootTools`, `dosfstools`,
  `e2fsprogs`, `mtools`, `parted`, … (image/flash tooling)

### Adding things

- New machine → `nixos-configurations/<name>/default.nix` + register in
  `parts/nixos-configurations/default.nix`
- New reusable NixOS module → `nixos-modules/<name>/` + register in
  `parts/nixos-modules/default.nix`
- New package → `packages/<name>/default.nix` + reference in
  `overlays/default.nix`

## Modules / key options

`hardware.onecloud` (`nixos-modules/nixos-onecloud/default.nix`):

- `enable` — turn on the port (kernel, bootloader, initrd, console, sysctl fix)
- `kernelPackage` / `ubootPackage` / `bootScrPackage` — override the packages
  (default: the flake-provided ones via `pkgs.onecloud.*`)
- `console` — `"both"` | `"display"` | `"serial"`
- `sdImage.enable` — also build a flashable image
- `sdImage.firmwarePartitionOffset` (16), `firmwareSize` (256), `compressImage` (false)
- `sdImage.rootSizeMiB` (6144) — pre-sized root, see above

Notable design constraints baked into the modules:

- `profiles/base.nix` and `hardware.enableAllHardware` are **not** used — they
  pull `efibootmgr`/`efivar` and x86/enterprise modules that are broken or
  unbuildable on 32-bit ARM.
- `boot.initrd.includeDefaultModules = false`; the initrd only needs the few
  real modules (`uas`, `virtio_net`) — the core drivers are built into the
  kernel.
- The initrd is gzip-compressed (the old Amlogic u-boot only understands gzip
  `uInitrd`).
- `/etc` is an immutable-ish rw overlay (`system.etc.overlay.enable`,
  erofs metadata + overlayfs in the initrd; needs `CONFIG_EROFS_FS=y` /
  `CONFIG_OVERLAY_FS=y`), with `services.userborn.enable` and
  `system.nixos-init.enable` for the modern, bashless 26.05 stack.
- `vm.mmap_rnd_bits` doesn't exist on 32-bit ARM → the generated sysctl file is
  neutralized so `systemd-sysctl` doesn't fail.
- A global uutils `replaceDependencies` overlay would break the systemd-initrd
  evaluation and is deliberately not applied.

> **FIXME(cross):** the `hardware.onecloud` module patches `fish`
> (`WITH_DOCS=false`) and `uutils-coreutils-noprefix`
> (`MANPAGES=n COMPLETIONS=n`) when cross-compiling, because their host-side
> doc/manpage generators link target libraries / compile host code with the
> target compiler. These are build hacks, not real fixes — see the comment in
> `nixos-modules/nixos-onecloud/default.nix`. Fix the cross builds (or upstream
> the flags) and delete the block.

## Consuming from another flake

The flake is designed to be consumed as an input (e.g. by `../nixos-config`,
which must not be edited by agents — only read):

```nix
# in the consumer's flake.nix
inputs.nixos-onecloud = {
  url = "github:lialh4qwq/nixos-onecloud";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-parts.follows = "flake-parts";
};
```

```nix
# in the machine/device module
imports = [ inputs.nixos-onecloud.nixosModules.nixos-onecloud ];

hardware.onecloud = {
  enable = true;
  sdImage.enable = true;   # optional: build a flashable image
};
```

`nixosModules.nixos-onecloud` is self-contained: it injects
`pkgs.onecloud.*` via the bundled overlay, imports the sd-image integration,
and carries the cross-build workarounds above, so a consumer does **not** need
to copy anything from this repo's `nixos-configurations/`.

## Development

Evaluate config without building (cheap smoke test):

```console
$ nix eval --impure .#nixosConfigurations.nixos-onecloud.config.system.stateVersion
```

Enter the tooling shell:

```console
$ nix develop
```
