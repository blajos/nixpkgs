{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  efivar,
  nix-update-script,
  popt,
}:

stdenv.mkDerivation rec {
  pname = "efibootmgr";
  version = "18";

  src = fetchFromGitHub {
    owner = "rhboot";
    repo = "efibootmgr";
    rev = version;
    hash = "sha256-DYYQGALEn2+mRHgqCJsA7OQCF7xirIgQlWexZ9uoKcg=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    efivar
    popt
  ];

  makeFlags = [
    "EFIDIR=nixos"
    "PKG_CONFIG=${stdenv.cc.targetPrefix}pkg-config"
  ];

  installFlags = [ "prefix=${placeholder "out"}" ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Linux user-space application to modify the Intel Extensible Firmware Interface (EFI) Boot Manager";
    homepage = "https://github.com/rhboot/efibootmgr";
    changelog = "https://github.com/rhboot/efibootmgr/releases/tag/${src.rev}";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "efibootmgr";
    platforms = lib.platforms.linux;
  };
}
