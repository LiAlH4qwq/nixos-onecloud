{
  imagemagick,
  lib,
  stdenv,
  ubootTools,
}:
# Boot script for OneCloud u-boot
# Based on Armbian's boot-onecloud.cmd, adapted for NixOS
stdenv.mkDerivation {
  pname = "onecloud-boot-scr";
  version = "1.0";

  nativeBuildInputs = [
    imagemagick
    ubootTools
  ];

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    # Generate boot.scr
    cat >boot.cmd <<'BOOTCMD'
    # OneCloud boot script for NixOS

    if test -n "''${bootdev}"; test $? != 0; then
      echo 'Set bootdev first:'
      echo '  eMMC: setenv bootdev "mmc 1"'
      echo '  SD:   setenv bootdev "mmc 0"'
      echo '  USB:  setenv bootdev "usb 0"; usb start'
      exit 22
    fi

    echo "Booting from ''${bootdev}"

    # Load environment
    fatload ''${bootdev} 0x20800000 /armbianEnv.txt && env import -t 0x20800000 ''${filesize}

    if test -n "''${rootdev}"; test $? != 0; then
      echo 'Set rootdev in armbianEnv.txt or manually'
      exit 22
    fi

    # Console setup
    if test -n "''${consoleargs}"; test $? != 0; then
      test -n "''${console}" || setenv console "both"
      setenv consoleargs ""
      test "''${console}" = "display" || test "''${console}" = "both" && setenv consoleargs "''${consoleargs} console=tty1"
      test "''${console}" = "serial" || test "''${console}" = "both" && setenv consoleargs "''${consoleargs} console=ttyAML0,115200n8"
      setenv consoleargs "''${consoleargs} no_console_suspend consoleblank=0"
    fi

    # Boot arguments
    setenv bootargs "root=''${rootdev} rootwait rw ''${consoleargs} ''${extraargs}"

    # Load and boot
    fatload ''${bootdev} 0x20800000 /uImage || exit 1
    fatload ''${bootdev} 0x22000000 /uInitrd || exit 1
    fatload ''${bootdev} 0x21800000 /dtb/meson8b-onecloud.dtb || exit 1

    bootm 0x20800000 0x22000000 0x21800000
    BOOTCMD

    mkimage -C none -A arm -T script -d boot.cmd boot.scr

    # Generate bootup.bmp
    convert \
      -size 640x360 \
      -background black \
      -gravity center -font "DejaVu-Sans" -pointsize 64 -fill white label:"NixOS" \
      BMP3:bootup.bmp

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp boot.scr "$out"/
    cp boot.cmd "$out"/
    cp bootup.bmp "$out"/
    runHook postInstall
  '';

  meta = {
    description = "Boot script and splash for OneCloud";
    platforms = lib.platforms.linux;
  };
}
