import ./make-test-python.nix ({ pkgs, ... }:
  let

    container = {
      # We re-use the NixOS container option ...
      boot.isContainer = true;
      # ... and revert unwanted defaults
      networking.useHostResolvConf = false;

      # use networkd to obtain systemd network setup
      networking.useNetworkd = true;
      networking.useDHCP = false;

      # systemd-nspawn expects /sbin/init
      boot.loader.initScript.enable = true;

      imports = [ ../modules/profiles/minimal.nix ];
    };

    containerSystem = (import ../lib/eval-config.nix {
      inherit (pkgs) system;
      modules = [ container ];
    }).config.system.build.toplevel;

    containerName = "container";
    containerRoot = "/var/lib/machines/${containerName}";

  in
  {
    name = "systemd-machinectl";

    nodes.machine = { lib, ... }: {
      # use networkd to obtain systemd network setup
      networking.useNetworkd = true;
      networking.useDHCP = false;

      # do not try to access cache.nixos.org
      nix.settings.substituters = lib.mkForce [ ];

      # auto-start container
      systemd.targets.machines.wants = [ "systemd-nspawn@${containerName}.service" ];

      virtualisation.additionalPaths = [ containerSystem ];

      # not needed, but we want to test the nspawn file generation
      systemd.nspawn.${containerName} = { };

      systemd.services."systemd-nspawn@${containerName}" = {
        serviceConfig.Environment = [
          # Disable tmpfs for /tmp
          "SYSTEMD_NSPAWN_TMPFS_TMP=0"
        ];
        overrideStrategy = "asDropin";
      };

      # open DHCP for container
      networking.firewall.extraCommands = ''
        ${pkgs.iptables}/bin/iptables -A nixos-fw -i ve-+ -p udp -m udp --dport 67 -j nixos-fw-accept
      '';
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("default.target");

      # create containers root
      machine.succeed("mkdir -p ${containerRoot}");

      # start container with shared nix store by using same arguments as for systemd-nspawn@.service
      machine.succeed("systemd-run systemd-nspawn --machine=${containerName} --network-veth -U --bind-ro=/nix/store ${containerSystem}/init")
      machine.wait_until_succeeds("systemctl -M ${containerName} is-active default.target");

      # Test machinectl stop
      machine.succeed("machinectl stop ${containerName}");

      # Install container
      # Workaround for nixos-install
      machine.succeed("chmod o+rx /var/lib/machines");
      machine.succeed("nixos-install --root ${containerRoot} --system ${containerSystem} --no-channel-copy --no-root-passwd");

      # Allow systemd-nspawn to apply user namespace on immutable files
      machine.succeed("chattr -i ${containerRoot}/var/empty");

      # Test machinectl start
      machine.succeed("machinectl start ${containerName}");
      machine.wait_until_succeeds("systemctl -M ${containerName} is-active default.target");

      # Test nss_mymachines without nscd
      machine.succeed('LD_LIBRARY_PATH="/run/current-system/sw/lib" getent -s hosts:mymachines hosts ${containerName}');

      # Test nss_mymachines via nscd
      machine.succeed("getent hosts ${containerName}");

      # Test systemd-nspawn network configuration to container
      machine.succeed("networkctl --json=short status ve-${containerName} | ${pkgs.jq}/bin/jq -e '.OperationalState == \"routable\"'");

      # Test systemd-nspawn network configuration to host
      machine.succeed("machinectl shell ${containerName} /run/current-system/sw/bin/networkctl --json=short status host0 | ${pkgs.jq}/bin/jq -r '.OperationalState == \"routable\"'");

      # Test systemd-nspawn network configuration
      machine.succeed("ping -n -c 1 ${containerName}");

      # Test systemd-nspawn uses a user namespace
      machine.succeed("test $(machinectl status ${containerName} | grep 'UID Shift: ' | wc -l) = 1")

      # Test systemd-nspawn reboot
      machine.succeed("machinectl shell ${containerName} /run/current-system/sw/bin/reboot");
      machine.wait_until_succeeds("systemctl -M ${containerName} is-active default.target");

      # Test machinectl reboot
      machine.succeed("machinectl reboot ${containerName}");
      machine.wait_until_succeeds("systemctl -M ${containerName} is-active default.target");

      # Restart machine
      machine.shutdown()
      machine.start()
      machine.wait_for_unit("default.target");

      # Test auto-start
      machine.succeed("machinectl show ${containerName}")

      # Test machinectl stop
      machine.succeed("machinectl stop ${containerName}");
      machine.wait_until_succeeds("test $(systemctl is-active systemd-nspawn@${containerName}) = inactive");

      # Test tmpfs for /tmp
      machine.fail("mountpoint /tmp");

      # Show to to delete the container
      machine.succeed("chattr -i ${containerRoot}/var/empty");
      machine.succeed("rm -rf ${containerRoot}");
    '';
  }
)
