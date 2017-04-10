{ stdenv, lib, bundlerEnv, ruby }:

bundlerEnv {
  name = "puppet-lint-2.0.2";

  inherit ruby;
  gemfile = ./Gemfile;
  lockfile = ./Gemfile.lock;
  gemset = ./gemset.nix;

  meta = with lib; {
    description = "Puppet Lint will test modules and manifests against the recommended Puppet style guidelines";
    homepage    = https://github.com/rodjek/puppet-lint;
    license     = with licenses; mit;
    maintainers = with maintainers; [ blajos ];
    platforms   = platforms.unix;
  };
}
