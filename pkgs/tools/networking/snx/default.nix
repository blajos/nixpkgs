{stdenv, patchelf, libX11, pam, tunctl}:
stdenv.mkDerivation {
  name = "snx";
  src = ./snx_install.tar.bz2;

  libPath = stdenv.lib.makeLibraryPath [
    stdenv.cc.cc
    libX11
    pam
  ];

  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase= ''
    mkdir snx
    cd snx
    tar -xjf $src
    '';

  installPhase = ''
    mkdir -p "$out/bin" "$out/lib"

    cp snx* "$out/bin"
    chmod +x "$out/bin/snx" "$out/bin/snx.real"

    cp libstdc++.so.5.0.7 "$out/lib"
    ln -s "$out/lib/libstdc++.so.5.0.7" "$out/lib/libstdc++.so.5"

    patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) --set-rpath "$libPath:$out/lib" "$out/bin/snx.real"
    '';
}
