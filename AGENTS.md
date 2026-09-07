# AGENTS.md

Guidance for AI agents and contributors working in this repository.

## What this is

A **flake-parts** flake that cross-compiles (from `x86_64-linux`) a full
NixOS image for the **XunLei OneCloud (Amlogic S805 / Meson8b)** board
(32-bit ARM). It provides a reusable NixOS module (`hardware.onecloud`), a
machine configuration, and the own packages it depends on (kernel, u-boot,
boot.scr, amlimg, toolchain).

**Supported build host:** `x86_64-linux`. Target: `armv7l-hf-multiplatform`
via `nixpkgs.crossSystem` (see `nixos-configurations/nixos-onecloud/default.nix`).

## Code regulations

Follow these rules exactly when writing or editing Nix code in this repo.
They exist to keep diffs small, the option set predictable, and the wiring
traceable; do not work around them.

1. **Attrsets**
   - Write nested attribute values as one literal attrset:
     `a = { b = 1; c = 2; };`.
   - Never split that into repeated dotted definitions
     (`a.b = 1; a.c = 2;`). Only decompose when you genuinely must merge
     across modules or `lib.mkIf`; even then prefer a single attrset with
     `lib.mkIf`/`lib.mkMerge` inside.

2. **Functions**
   - Sort destructured arguments alphabetically, both at the function
     definition (`{ config, flakeConfig, lib, pkgs, root, ... }`) and at the
     call site (`{ inherit flakeConfig root; inherit (config.flake) ...; }`).
   - Keep `...` last.

3. **Module options**
   - Do not restate an option that another option already implies. If setting
     `a.b` implies `c.d` (through module defaults), a config that uses `a.b`
     must not add a redundant `c.d`. Only set `c.d` when deliberately deviating
     from what `a.b` implies.

4. **Module files & layering**
   - Every component is a directory with a `default.nix`
     (`a/b/default.nix`), referenced as `imports = [ a/b ]`. Do not create flat
     single files such as `a/b.nix`.
   - Do not jump layers. Import strictly one level at a time: `a/default.nix`
     imports `./b` (i.e. `a/b`), and `b/default.nix` imports `./c` (i.e.
     `a/b/c`). Never let `a` reach into `a/b/c` directly.

5. **Module structure & wiring**
   - Dependency/ownership graph (top level `flake.nix` always routes through
     `parts/`):
     `flake.nix -(uses)-> parts/ -(wires)-> { packages, overlays, nixos-modules, nixos-configurations }`.
     `parts/` is the single place that turns repo directories into flake
     outputs; keep repo-level concerns in the four top-level directories, not
     in `parts/`.
   - To add a new package follow the chain
     `packages/<name>/default.nix -(reference in)-> overlays/default.nix -(exposed as flake.overlays by)-> parts/overlays -(injected into NixOS pkgs by)-> parts/nixos-modules -(consumed by)-> nixos-configurations`.
   - Never use the flake input `self`. To reach the flake root use the
     `root` specialArg; to read flake-level values use `config.flake`. When
     calling a nested module system, pass them explicitly, e.g.
     `specialArgs = { inherit root; flakeConfig = config; };`.

## Layout & where things go

| Concern | Directory | Registered in |
| --- | --- | --- |
| NixOS module (`hardware.onecloud`) | `nixos-modules/nixos-onecloud/` | `parts/nixos-modules/default.nix` |
| Machine configuration | `nixos-configurations/<name>/default.nix` | `parts/nixos-configurations/default.nix` |
| Own packages | `packages/<name>/default.nix` | `overlays/default.nix` (via `pkgs.onecloud.*`) |
| Top-level flake wiring (outputs) | `parts/` | `flake.nix` imports `./parts` |

- `parts/nixos-modules` injects the onecloud overlay into NixOS pkgs
  (`nixpkgs.overlays = [ config.flake.overlays.nixos-onecloud ]`). The module
  files themselves must **not** reference `config.flake.*` — that only exists
  in flake-parts scope.
- A new machine config imports the module with
  `imports = [ flakeConfig.flake.nixosModules.nixos-onecloud ]`
  (`flakeConfig` is passed via `specialArgs`).

## Commands

Verification is cheap; building the image is expensive (cross kernel + full
system). Prefer evaluation over building:

```console
# cheap smoke test (no build)
nix eval --impure .#nixosConfigurations.nixos-onecloud.config.system.stateVersion

# inspect specific options (no build)
nix eval --impure .#nixosConfigurations.nixos-onecloud.config.sdImage.rootSizeMiB

# full image (slow; do only when asked)
nix build .#nixosConfigurations.nixos-onecloud.config.system.build.sdImage

# tooling shell
nix develop
```

`flake-parts` lazily evaluates, so a syntax/module error may only surface once
the path you evaluate pulls it in. After touching module wiring, always run the
smoke test above (it evaluates the whole NixOS module set).

## Hard-won constraints (do not "clean up")

- **Root filesystem must be pre-sized.** `make-ext4-fs.nix` leaves only ~16 MiB
  slack; first boot also has to write the Nix store DB, `systemd-logind`/`dhcpcd`
  `StateDirectory`s, and the persistent journal. If the root is not grown the
  disk fills and login breaks (`ENOSPC`, `System error`). The image therefore
  pre-sizes the root via `sdImage.rootSizeMiB` (default `6144`, fits an 8 GiB
  eMMC) and overrides `expand-root-partition` to be best-effort and quiet.
  Keep `rootSizeMiB` ≤ ~6300 MiB so the image still fits the 7.28 GiB eMMC.
- **`boot.scr` builds its own kernel cmdline** and **ignores
  `boot.kernelParams`**. Kernel params for the real boot path must go into
  `armbianEnv.txt` `extraargs` in `nixos-modules/nixos-onecloud/sdimage.nix`.
  (Keeping them in `boot.kernelParams` too only covers the extlinux path.)
- **Don't** import `profiles/base.nix` or enable `hardware.enableAllHardware`
  (pulls `efibootmgr`/`efivar` and modules that are broken/unbuildable on
  32-bit ARM). Don't apply a global uutils overlay (breaks systemd-initrd
  evaluation). Keep `boot.initrd.includeDefaultModules = false` and the initrd
  gzip-compressed (old u-boot only loads gzip `uInitrd`).
- **Kernel config is `linuxManualConfig`** over the Armbian `linux-meson`
  config. Appended options are dropped by `olddefconfig` unless their
  dependencies are set first (e.g. hung-task detectors need `CONFIG_DEBUG_KERNEL=y`).
  NixOS 26.05 needs `CONFIG_EROFS_FS=y`, `CONFIG_EROFS_FS_ZIP=y`,
  `CONFIG_OVERLAY_FS=y` built-in for the `/etc` overlay stack.
- `/etc` overlay + `services.userborn.enable` + `system.nixos-init.enable` +
  `users.mutableUsers = false` are intentional (bashless, modern 26.05 init).
  Users/passwords are declared in the machine config (`nixos`/`nixos`,
  `root`/`nixos` — test credentials).
- A `systemd.log_level=debug` flag is currently enabled on **both** cmdline
  paths while the reflash is verified — remove both when done.

## Root-cause reference (the ENOSPC saga)

Symptoms seen on-device: `register-nix-paths`, `systemd-logind` and `dhcpcd`
fail with `No space left on device`; login reports `System error`;
`pam_lastlog2` reports `database or disk is full`. Root cause: un-grown,
near-full root filesystem at first boot. Diagnose a booted image by dumping the
root partition and reading its journal without mounting (no root needed):

```console
dd if=/dev/sdX2 of=booted-p2.img bs=1M status=progress
nix shell nixpkgs#e2fsprogs -c debugfs -R 'ls -l /var/log/journal' booted-p2.img
# extract system.journal, then:
nix shell nixpkgs#systemd -c journalctl --file system.journal -b -p 0..4 --no-pager
```

## Git / hygiene

- Commit small, focused changes; match existing style (uppercase `--` section
  comments in modules, `lib.mkIf`/`mkDefault` conventions).
- `.gitignore` ignores `result`. **Never commit** raw disk dumps or images
  (`$in`, `*.p2.img`, `*.img` from `dd`, `booted-p2.img`, …).
- Don't commit changes to `flake.lock` unless inputs changed intentionally.
- Re-running full builds to test small edits is expensive; reason + evaluate
  first, then let the user build/flash.
