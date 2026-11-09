{ pkgs, ... }:

{
  # Set reverse-path filtering to loose mode (2).
  # Essential when packets arrive via wg0 carrying foreign source IPs,
  # preventing the kernel from dropping incoming traffic due to asymmetric routing.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
  };

  # Make sure iproute2 and wireguard-tools are available on the system
  environment.systemPackages = with pkgs; [
    wireguard-tools
    iproute2
  ];

  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.10.0.3/32" ];
    table = "off";

    # Path to your private key file (kept out of the Nix store for security)
    privateKeyFile = "/etc/wireguard/wg0.key";

    # Setup source-based policy routing
    postUp = ''
      # Reach pool peers directly
      ${pkgs.iproute2}/bin/ip route replace 10.10.0.0/24 dev wg0

      # Create default route in table 200 pointing out the tunnel
      ${pkgs.iproute2}/bin/ip route replace default dev wg0 table 200

      # Route anything sourced from 10.10.0.3 via table 200
      ${pkgs.iproute2}/bin/ip rule del from 10.10.0.3 lookup 200 priority 100 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule add from 10.10.0.3 lookup 200 priority 100
    '';

    # Clean up routes and rules on interface teardown
    preDown = ''
      ${pkgs.iproute2}/bin/ip rule del from 10.10.0.3 lookup 200 priority 100 || true
      ${pkgs.iproute2}/bin/ip route del default dev wg0 table 200 || true
      ${pkgs.iproute2}/bin/ip route del 10.10.0.0/24 dev wg0 || true
    '';

    peers = [
      {
        publicKey = "gIUv3LR5Xu6Otb/0jVzQwKIOz5lbHHhx+oOoQQ497UI=";
        presharedKeyFile = "/etc/wireguard/wg0.psk";
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "ORACLE_IP:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
