{ stdenv, fetchFromGitHub, pkgconfig, zlib, pcsclite, boost,
}:

stdenv.mkDerivation rec {
  name = "libgtop11dotnet-${version}";
  version = "ab32e90";

  src = fetchFromGitHub {
    owner = "blajos";
    repo = "libgtop11dotnet";
    rev = version;
    sha256 = "1z4d621ip1zjicpwr0pxalnf4020ly0x3xp5skbkvl7b24wfl4ql";
  };

  postPatch = ''
    sed -i 's,$(DESTDIR),$(out),g' Makefile.am
  '';

  buildInputs = [
    pkgconfig pcsclite boost zlib
  ];

  configureFlags = [
    "--enable-system-boost"
  ];

  installFlags = [
    "sysconfdir=\${out}/etc"
  ];

  meta = with stdenv.lib; {
    description = "Gemalto PKCS11 Library";
    homepage = https://github.com/blajos/libgtop11dotnet;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ blajos ];
    platforms = platforms.all;
  };
}
