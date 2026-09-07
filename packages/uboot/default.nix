{
  bc,
  fetchFromGitHub,
  imagemagick,
  lib,
  stdenv,
  toolchain,
}:
stdenv.mkDerivation {
  pname = "uboot-onecloud";
  version = "2011.03-onecloud";

  src = fetchFromGitHub {
    owner = "hzyitc";
    repo = "u-boot";
    rev = "0038d741ed1c77a77570c3a6bf88fe6189c11733";
    hash = "sha256-3kLITZBmorzzNepoBOH/fGbyHsFd2mVAN92Kvfzo8kU=";
  };

  nativeBuildInputs = [
    bc
    imagemagick
    toolchain
  ];

  CROSS_COMPILE = "arm-none-eabi-";

  # Old u-boot uses /bin/pwd which doesn't exist in NixOS sandbox
  preConfigure = ''
    mkdir -p /bin
    # Patch all references to /bin/pwd in Makefiles
    find . -name Makefile -exec sed -i 's|/bin/pwd|pwd|g' {} \;
    # Build bin2code host tool from source (the repo has ARM prebuilts, not host)
    gcc -o arch/arm/cpu/aml_meson/common/firmware/bin2code tools/bin2code.c
    # Make all prebuilt host tools executable
    find . -name bin2code -exec chmod +x {} \;
  '';

  configurePhase = ''
    runHook preConfigure

    make m8b_onecloud_config

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    make -j$NIX_BUILD_CORES

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp build/u-boot.bin "$out"/
    cp build/ddr_init.bin "$out"/
    cp build/u-boot-comp.bin "$out"/

    runHook postInstall
  '';

  dontFixup = true;

  meta = {
    description = "U-Boot for XunLei OneCloud (Amlogic S805 / Meson8b)";
    homepage = "https://github.com/hzyitc/u-boot";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
