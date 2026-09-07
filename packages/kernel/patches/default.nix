{ fetchurl }:
# Armbian meson-6.12 kernel patches for Meson8/8b/8m2 support
# Includes: USB, Ethernet, DRM/display, TrustZone, CVBS, GPIO, DTS, clock patches
let
  base = "https://raw.githubusercontent.com/armbian/build/main/patch/kernel/archive/meson-6.12";

  patch =
    name: hash:
    fetchurl {
      url = "${base}/${name}";
      inherit hash;
    };
in
[
  # --- USB ---
  (patch "0007-dt-bindings-phy-meson8b-usb2-Add-support-for-reading.patch" "sha256-bd4LfwwjeUqxwv+woM1D79GKQyWBuQtXTuZxBBAjnts=")
  (patch "0008-phy-amlogic-meson8b-usb2-Add-support-for-reading-the.patch" "sha256-Dd77UTv6R8YWQadmmw7HaIyr+EohxjdqZuBvPccIGD0=")
  (patch "0009-usb-common-usb-conn-gpio-Fall-back-to-polling-the-GP.patch" "sha256-aMpUX9N326slW3Mzb5Cy0rS151ttodC78nSZ99C/YQ8=")
  (patch "0010-usb-dwc2-register-child-USB-connector-devices.patch" "sha256-/6I/07OHuj5Z0CqFtSzhuVweBVzVowQb5k2R6qWLnfM=")

  # --- GPIO ---
  (patch "0011-ARM-dts-meson-Add-GPIO-controller-capabilities-to-th.patch" "sha256-e9iqGHl9Aqh0K/zKoHrPAmsmQSzcwhDl2Twb6L3E7YQ=")
  (patch "0012-ARM-dts-meson8b-odroidc1-Enable-the-Micro-USB-OTG-co.patch" "sha256-DB8NTahg4pR9mztkfxCxK07iWErLdMGJaubMZwBgX7Q=")

  # --- CVBS Display ---
  (patch "0013-dt-bindings-phy-Add-bindings-for-the-Amlogic-Meson-C.patch" "sha256-D4Quso73rozqXsMlroG0v3bGQh+tBG2Zh2d1Zlw4BmY=")
  (patch "0014-phy-amlogic-Add-a-new-driver-for-the-CVBS-DAC-CVBS-P.patch" "sha256-vqay7+b3WvCmEe/Br6LKVaNl561skC3DyIDfFTH8eFU=")
  (patch "0015-dt-bindings-display-meson-vpu-Add-the-CVBS-DAC-prope.patch" "sha256-6YzkAu1u9rURhfOY61usXPj2q+ckBlpYXafusisYWLk=")
  (patch "0016-drm-meson-Add-support-for-using-a-PHY-for-the-CVBS-D.patch" "sha256-CVX++aBh33hbUjIUnq1TzaVLx15yX9yQZYKsGne+oko=")

  # --- Ethernet ---
  (patch "0018-dt-bindings-clock-meson8b-Add-the-RMII-reference-clo.patch" "sha256-6ljJOqfGG7XitUmtaK+fOtxk4eKOAtGSWprEVCAFpEA=")
  (patch "0019-dt-bindings-clock-meson8b-Add-the-Meson8-Ethernet-RM.patch" "sha256-V0Ayhooja+pzsTKlluoM9EpiORsG5qt0GY/wYO6PVQo=")
  (patch "0020-clk-meson-meson8b-Add-the-Ethernet-RMII-clock-tree-o.patch" "sha256-b1HW0/1HrrT2GkmLbMNvIbJUhLoCsi0c55Q2snX12wI=")
  (patch "0021-dt-bindings-net-dwmac-meson-Add-the-Ethernet-clock-i.patch" "sha256-qwNpCRnqCwUp0uND/ZezeXg/YrarTx3FMf6EYndWqnQ=")
  (patch "0022-net-stmmac-dwmac-meson-Rename-the-SPEED_100-macro.patch" "sha256-u8aYdgzXIud3v4ggGv7wV7w6WF0GqxF3JpMfrDgg8EU=")
  (patch "0023-net-stmmac-dwmac-meson-Manage-the-ethernet-clock.patch" "sha256-S8YOAo7vFBgwGhgKXrGEabHs4Lbq5XqqH8mSUHzH/+8=")
  (patch "0024-net-stmmac-dwmac-meson-Initialize-all-known-PREG_ETH.patch" "sha256-ZafvVJac2V/VSkhfXsrjgf47E/IyvmVGtuak7BMWH2Q=")

  # --- Ethernet DTS ---
  (patch "0025-ARM-dts-meson-meson8-Add-the-clock-input-to-the-Ethe.patch" "sha256-rz47cz08vBc25Sif0jEQFlmQ8BsA7z+P832IYSvu11E=")

  # --- Clock ---
  (patch "0026-dt-bindings-clock-meson8b-add-the-rtc_32k-oscillator.patch" "sha256-Q/6WN9zAdX/bgBUPIz36Oz32DV3IRCjkoy/M2Y1047Q=")
  (patch "0027-clk-meson-meson8b-Add-the-mpeg_rtc_osc_sel-clock.patch" "sha256-7BThza+bubixAUskzmzmN5wvSd1AGxeulluQOdXd5rk=")

  # --- DTS base ---
  (patch "0028-ARM-dts-meson-Add-address-cells-size-cells-and-range.patch" "sha256-u9MPcr+TVgW1iSUo6UFVTnSmQ5qX4Iup28v8kNfBTAw=")

  # --- TrustZone ---
  (patch "0029-dt-bindings-firmware-Document-the-Amlogic-Meson6-8-8.patch" "sha256-VXhvTMp+LxFAL/EMHchFEy/elv+d1taKQJOA2Irc81Q=")
  (patch "0030-dt-bindings-arm-cpus-Document-Meson8-TrustZone-firmw.patch" "sha256-rgaCF5561bq23AiDD0RiBf5NyZiVXFj7lUZVwHsPrp0=")
  (patch "0031-ARM-meson-Add-support-for-the-TrustZone-firmware.patch" "sha256-75c4Y9svRtN6ygG82qRituaSdfvJptKTtV7ie12+B70=")
  (patch "0032-ARM-meson-platsmp-Add-support-for-SoCs-running-on-Tr.patch" "sha256-bSshjvy37rAkcavFWa9YgyGSlt8jC50q5HSLbSLoPoY=")
  (patch "0033-soc-amlogic-meson-mx-socinfo-Add-support-for-the-Tru.patch" "sha256-pGHNGyY7oe9szOXGKBo2SI2zTaerVeD30k0zaJg8NGo=")
  (patch "0034-nvmem-meson-mx-efuse-Add-support-for-the-TrustZone-f.patch" "sha256-OXdFJJPDbJOiluSjr3IIfIm04B/OGsMaLjwYeCI6lOI=")

  # --- PWM ---
  (patch "0036-ARM-dts-meson8-Add-the-PWM_C-DV9-and-PWM_D-pins.patch" "sha256-FDJCgrXq8xa+VENTE4PrwIC4BFP4Dswb/plBqtwlSWw=")

  # --- DRM/Display ---
  (patch "0045-dt-bindings-display-meson-vpu-add-support-for-Meson8.patch" "sha256-i3zO3cXslpLvkGnpE5MR+Sykz7OjAwUwLdTl0rxryFU=")
  (patch "0046-drm-meson-add-Meson8-Meson8b-Meson8m2-specific-vpu_c.patch" "sha256-rVt0LS102HTZQtsRX0JQDdIhl/rEBFPyAAzph02ukM8=")
  (patch "0047-drm-meson-Use-24-bits-per-pixel-for-the-framebuffer-.patch" "sha256-o/Fu2ImMOR46qS11JMNfmQZ/vVyr2iCfdxL/cLIAt1c=")
  (patch "0048-drm-meson-Use-a-separate-list-of-supported-formats-f.patch" "sha256-Rl2j+6B0ZYhBztdwqSwWKs8fDexRPzedyome+Wh3nIc=")
  (patch "0049-drm-meson-Skip-VIU_OSD1_CTRL_STAT2-alpha-replace-val.patch" "sha256-mtK4k+txXKt/lswmerq2SvVpm2noawc0/JRWEg/nNhk=")
  (patch "0050-drm-meson-Enable-the-RGB-to-YUV-converter-on-Meson8-.patch" "sha256-k/kpe7Zwo1V4s5S7eieR6u7uYsN+CpF/k3ys0WaPsx0=")
  (patch "0051-drm-meson-Update-meson_vpu_init-to-work-with-Meson8-.patch" "sha256-+7czd/fwRxGYrXxTbdamNIRwmb5qo4dZlsqVhp+qmok=")
  (patch "0052-drm-meson-Describe-the-HDMI-PHY-frequency-limits-of-.patch" "sha256-9P9PqQFTl8FrdLcrD0MbaL/iPDTVKYhqj2P14mGBNT8=")
  (patch "0053-drm-meson-Update-the-HDMI-encoder-for-Meson8-8b-8m2.patch" "sha256-R/+UrfMDm2jIg8yyIDCKfflcr70LyVkJy0H74dB2fSg=")
  (patch "0054-drm-meson-Only-set-ycbcr_420_allowed-on-64-bit-SoCs.patch" "sha256-Vt1ZFsjqi3Q0GEY57k6xdCoIYGmz18q5FvrkX0BaVQg=")
  (patch "0055-drm-meson-Make-the-HHI-registers-optional-WIP.patch" "sha256-tD7JibrOvliGTc8gNImZtcgx3ubbpxuE4V9zumevSVI=")
  (patch "0056-drm-meson-Add-support-for-the-Meson8-8b-8m2-TranSwit.patch" "sha256-xia0KhlMinNseNR3Tc/Cepza/W7cFzE1hZsOhSW6pMg=")
  (patch "0057-drm-meson-Meson8-Meson8b-Meson8m2-VCLK-HACK.patch" "sha256-aR70HKqwsrKMuTYbBU4VedZwYy3P5X4pgaOH5wr0uTE=")
  (patch "0058-drm-meson-Enable-support-for-Meson8-Meson8b-Meson8m2.patch" "sha256-vGP126F+Awo8OhYzwhW/+RxqlRFGeAEEV6Iyo2Ok5jI=")

  # --- HDMI/VPU DTS ---
  (patch "0059-ARM-dts-meson-add-the-VPU-WiP.patch" "sha256-fYAr6nLeDNCxwWYV0faiV8qPDN5nzNj44O8oy5dx96M=")
  (patch "0060-ARM-dts-meson8-add-the-HDMI-controller-WiP.patch" "sha256-bZf9F9sn0itdDqo/7JTABtXwxn8vJax8Ol07G6xjEfE=")
  (patch "0061-ARM-dts-meson8-Add-the-shared-CMA-dma-memory-pool.patch" "sha256-/cfStsvzK3syZKASqMXi9V9RjsT8bPoBBVGAXVFoOq4=")
  (patch "0062-ARM-dts-meson8-add-the-AO-CEC-controller-WiP.patch" "sha256-/5v4zfYJWfkCnJA3Eln3LZIJlU5CenhDdrNOJyGDpYI=")
  (patch "0063-ARM-dts-meson8b-add-the-HDMI-controller-WiP.patch" "sha256-mcCNiN82KQNSWgZ4GUpXgHk7+JbJNiYN+4sjbTzrbNE=")
  (patch "0064-ARM-dts-meson8b-add-the-AO-CEC-controller-WiP.patch" "sha256-C3SzbdbOmzHKyh7vS+6qJm3R4DD23e6ufK7n/sovsfY=")
  (patch "0066-ARM-dts-meson8b-odroid-c1-enable-HDMI-for-the-Odroid.patch" "sha256-8PSJ2447GCaefpXn4IFT5ScgPgsI9bgL+B77GEVit0Y=")
  (patch "0067-meson8b-mxq-add-HDMI-support.patch" "sha256-ytUGvk1pb1NSPmT1tzIrviZfeXEPOeN9i2ZrWOyP6qw=")

  # --- PWM fix ---
  (patch "generic-Revert-pwm-meson-modify-and-simplify-calculation-in-.patch" "sha256-jYPDsqtGRuxGonCwT8utMFPMiRGXrFMsbhS91OXDDLg=")

  # --- XunLei OneCloud DTS ---
  (patch "onecloud-0001-add-dts.patch" "sha256-BD/TBWaelntBAnSrm9MACl+kIxbMUzm4Guk6+glTS+g=")
  (patch "onecloud-0002-dts-Support-HDMI.patch" "sha256-CNYrHPJv4p0t/9/P/3JLdTiHS5O+ICt4/NYDLIVzFlc=")
]
