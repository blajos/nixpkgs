{ stdenv, fetchurl, makeWrapper, pkgconfig, utillinux, which
, procps, libcap_ng, openssl, python27 , perl
, kernel ? null }:

with stdenv.lib;

let
  _kernel = kernel;
  python = python27.withPackages (ps: with ps; [ six ]);
in stdenv.mkDerivation rec {
  version = "2.12.0";
  pname = "openvswitch";

  src = fetchurl {
    url = "http://openvswitch.org/releases/${pname}-${version}.tar.gz";
    sha256 = "1y78ix5inhhcvicbvyy2ij38am1215nr55vydhab3d4065q45z8k";
  };

  kernel = optional (_kernel != null) _kernel.dev;

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ makeWrapper utillinux openssl libcap_ng python
                  perl procps which ];

  configureFlags = [
    "--localstatedir=/var"
    "--sharedstatedir=/var"
    "--sbindir=$(out)/bin"
  ] ++ (optionals (_kernel != null) ["--with-linux"]);

  # Leave /var out of this!
  installFlags = [
    "LOGDIR=$(TMPDIR)/dummy"
    "RUNDIR=$(TMPDIR)/dummy"
    "PKIDIR=$(TMPDIR)/dummy"
  ];

  postBuild = ''
    # fix tests
    substituteInPlace xenserver/opt_xensource_libexec_interface-reconfigure --replace '/usr/bin/env python' '${python.interpreter}'
    substituteInPlace vtep/ovs-vtep --replace '/usr/bin/env python' '${python.interpreter}'
  '';

  enableParallelBuilding = true;
  doCheck = false; # bash-completion test fails with "compgen: command not found"

  meta = with stdenv.lib; {
    platforms = platforms.linux;
    description = "A multilayer virtual switch";
    longDescription =
      ''
      Open vSwitch is a production quality, multilayer virtual switch
      licensed under the open source Apache 2.0 license. It is
      designed to enable massive network automation through
      programmatic extension, while still supporting standard
      management interfaces and protocols (e.g. NetFlow, sFlow, SPAN,
      RSPAN, CLI, LACP, 802.1ag). In addition, it is designed to
      support distribution across multiple physical servers similar
      to VMware's vNetwork distributed vswitch or Cisco's Nexus 1000V.
      '';
    homepage = http://openvswitch.org/;
    license = licenses.asl20;
    maintainers = [ maintainers.netixx ];
  };
}
