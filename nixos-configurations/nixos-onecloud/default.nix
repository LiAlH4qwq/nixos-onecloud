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

  documentation.enable = false;
  environment = {
    defaultPackages = lib.mkDefault [ ];
    systemPackages = with pkgs; [
      btrfs-progs
      fastfetch
    ];
  };
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
