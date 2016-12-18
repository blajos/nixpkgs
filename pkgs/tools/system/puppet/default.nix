{ stdenv, lib, bundlerEnv, ruby }:

bundlerEnv {
  name = "puppet-4.8.1";

  inherit ruby;
  gemfile = ./Gemfile;
  lockfile = ./Gemfile.lock;
  gemset = ./gemset.nix;

  meta = with lib; {
    description = "Puppet configuration management system";
    homepage    = http://puppet.com;
    license     = with licenses; gpl;
    maintainers = with maintainers; [ blajos ];
    platforms   = platforms.unix;
  };
}
