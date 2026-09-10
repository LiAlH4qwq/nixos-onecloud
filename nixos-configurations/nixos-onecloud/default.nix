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
