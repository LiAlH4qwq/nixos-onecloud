{
  autoPatchelfHook,
  fetchurl,
  lib,
  libxcrypt-legacy,
  ncurses5,
  stdenv,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "gcc-linaro-arm-none-eabi-bin";
  version = "4.8-2014.04";

  src = fetchurl {
    url = "https://mirrors.dotsrc.org/armbian-dl/_toolchain/gcc-linaro-arm-none-eabi-${finalAttrs.version}_linux.tar.xz";
    hash = "sha256-mLmbf6LrJo0VhjnbKpuLy0Nh6UCHvSzinyYZm9Cc9Fk=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    libxcrypt-legacy
    ncurses5
    stdenv.cc.cc
    zlib
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r . "$out"

    runHook postInstall
  '';

  meta = {
    description = "Linaro GCC ARM bare-metal toolchain";
    homepage = "https://developer.arm.com/tools-and-software/gnu-toolchain";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "i686-linux" ];
  };
})
