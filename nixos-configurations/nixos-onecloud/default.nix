{ lib, ... }: {
  nixpkgs.crossSystem = lib.systems.examples.armv7l-hf-multiplatform;

  hardware.onecloud.enable = true;
  hardware.onecloud.sdImage.enable = true;

  documentation.enable = false;
  environment.defaultPackages = lib.mkDefault [ ];
  security.sudo-rs.enable = true;
  services.userborn.enable = true;
  system.etc.overlay.enable = true;
  system.nixos-init.enable = true;

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
