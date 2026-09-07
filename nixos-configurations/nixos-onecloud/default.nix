{
  flakeConfig,
  lib,
  pkgs,
  ...
}:
{
  imports = [ flakeConfig.flake.nixosModules.nixos-onecloud ];

  nixpkgs.crossSystem = lib.systems.examples.armv7l-hf-multiplatform;

  hardware.onecloud.enable = true;
  hardware.onecloud.sdImage.enable = true;

  # fish 4.x builds its host-side Rust `xtask` helper while generating its
  # docs (`cmake/Docs.cmake`). Under a cross build the pkg-config environment
  # only points at the *target* (armv7l) pcre2, so the x86_64 xtask link fails
  # ("skipping incompatible … libpcre2-8.so"). Docs are useless on this board,
  # so drop WITH_DOCS (and the untestable cross test-run).
  nixpkgs.overlays = [
    (final: prev: {
      fish = prev.fish.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (lib.cmakeBool "WITH_DOCS" false) ];
        doCheck = false;
      });
    })
    (final: prev: {
      # The GNUmakefile's `build-uudoc` (manpages/completions) does a host
      # build of `uudoc` but keeps the cross CC set, so blake3's build script
      # tries to assemble x86-64 SSE code with the armv7 compiler (-m64) and
      # fails. Manpages/completions are pointless on this board already, so
      # skip them.
      uutils-coreutils-noprefix = prev.uutils-coreutils-noprefix.overrideAttrs (old: {
        makeFlags = (old.makeFlags or [ ]) ++ [ "MANPAGES=n" "COMPLETIONS=n" ];
      });
    })
  ];

  documentation = {
    enable = false;
    man.enable = false;
  };
  environment.defaultPackages = lib.mkDefault [ ];
  programs.fish.enable = true;
  # NOTE: there is no `programs.nushell` module in this nixpkgs revision, so nu
  # is installed as a plain package. Pick the login shell per-user via
  # `users.users.<name>.shell = pkgs.nushell`.
  environment.systemPackages = with pkgs; [
    btrfs-progs
    fastfetch
    nushell
    uutils-coreutils-noprefix
  ];
  security.sudo-rs.enable = true;
  services.userborn.enable = true;
  system = {
    etc.overlay.enable = true;
    nixos-init.enable = true;
    tools.nixos-generate-config.enable = false;
  };

  users = {
    mutableUsers = false;
    users = {
      nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "nixos";
      };
      root.password = "nixos";
    };
  };

  system.stateVersion = "26.05";
}
