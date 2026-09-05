{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "amlimg";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "hzyitc";
    repo = "AmlImg";
    rev = "v${version}";
    hash = "sha256-/Vo5/4N06qMwSHI6YkrzPi5wQz1yGBMTcWW7Al9/4I4=";
  };

  # No third-party Go modules (stdlib only).
  vendorHash = null;

  meta = {
    description = "Amlogic image packing tool";
    homepage = "https://github.com/hzyitc/AmlImg";
    license = lib.licenses.mit;
    mainProgram = "AmlImg";
    platforms = lib.platforms.linux;
  };
}
