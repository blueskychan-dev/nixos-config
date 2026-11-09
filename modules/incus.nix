{ config, lib, pkgs, ... }:

{
  # Incus (LXC containers + VMs)
  virtualisation.incus = {
    enable = true;
    ui.enable = true;   # web UI at https://127.0.0.1:8443 once https listener is set

    # Declarative initial setup (applied on every boot, idempotent)
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.0.100.1/24";
            "ipv4.nat" = "true";
            "ipv6.address" = "none";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "dir";
          config.source = "/var/lib/incus/storage-pools/default";
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
              size = "35GiB";
            };
          };
        }
      ];
    };
  };

  # Incus requires the nftables firewall backend on NixOS
  networking.nftables.enable = true;

  # Let containers get DHCP/DNS from incus and reach the outside
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  users.users.mind.extraGroups = [ "incus-admin" ];

  # `ct-login [container]`: TUI menu to pick a container and a user to log in as
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "ct-login";
      runtimeInputs = [ pkgs.newt config.virtualisation.incus.package pkgs.gawk ];
      text = ''
        ask() { whiptail --title "Incus login" --menu "$1" 20 64 10 "''${@:2}" 3>&1 1>&2 2>&3; }

        ct="''${1:-}"
        if [ -z "$ct" ]; then
          mapfile -t rows < <(incus list -f csv -c ns)
          if [ "''${#rows[@]}" -eq 0 ]; then echo "No containers found."; exit 1; fi
          menu=()
          for r in "''${rows[@]}"; do menu+=("''${r%%,*}" "''${r#*,}"); done
          ct=$(ask "Choose a container" "''${menu[@]}") || exit 0
        fi

        if [ "$(incus list "^$ct\$" -f csv -c s)" != "RUNNING" ]; then
          echo "Starting $ct..."; incus start "$ct"
          until incus exec "$ct" -- systemctl is-system-running --quiet --wait 2>/dev/null; do sleep 1; done
        fi

        mapfile -t users < <(incus exec "$ct" -- getent passwd \
          | awk -F: '$3==0 || ($3>=1000 && $3<65534) {print $1 ":" $5}')
        umenu=()
        for u in "''${users[@]}"; do
          n="''${u%%:*}"; d="''${u#*:}"; umenu+=("$n" "''${d:-user}")
        done
        user=$(ask "Log in to $ct as" "''${umenu[@]}") || exit 0

        clear
        exec incus exec "$ct" -t -- login -f "$user"
      '';
    })
  ];
}
