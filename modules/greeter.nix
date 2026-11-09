{ config, lib, pkgs, ... }:
# Login screen: greetd + ReGreet, "soft card" theme (matches the hyprlock lock screen).
# Theme CSS:   ./regreet.css
# Images:      /var/lib/greeter-theme/{background,avatar}.png — written by
#              ~/.config/sway/greeter-sync.sh (runs whenever you change wallpaper / lock).
#
# ReGreet runs inside a tiny sway session (not cage), because only sway can force
# the monitor modes: DP-1 (Acer) 1920x1080@320 with the login card, DP-2 (MSI)
# 1920x1080@180 showing the wallpaper — same as the desktop session.
let
  greeterSway = pkgs.writeText "greeter-sway.conf" ''
    # Monitors — keep in sync with ~/.config/sway/config
    output DP-1 mode 1920x1080@320Hz position 0 0
    output DP-2 mode 1920x1080@179.998Hz position 1920 0
    output * bg /var/lib/greeter-theme/background.png fill #1e1e2e
    swaybg_command ${pkgs.swaybg}/bin/swaybg

    # Login card on the main (320 Hz) screen, fullscreen, no borders.
    # Outputs come up in random order at boot, so workspace 1 can land on DP-2
    # before any rule applies. Instead, move the ReGreet window to DP-1 the
    # moment it maps (both outputs exist by then), then fullscreen it there.
    workspace number 1 output DP-1
    default_border none
    for_window [app_id="apps.regreet"] move container to output DP-1, focus, fullscreen enable

    # Keyboard: same layouts as the desktop; Super+Space switches us/th
    input type:keyboard xkb_layout "us,th"
    bindsym Mod4+space input type:keyboard xkb_switch_layout next
    seat * hide_cursor 8000

    # ReGreet starts the real session; when it exits, end this greeter sway
    exec "${config.programs.sway.package}/bin/swaymsg focus output DP-1; ${lib.getExe config.services.displayManager.regreet.package}; ${config.programs.sway.package}/bin/swaymsg exit"
  '';
in
{
  services.displayManager.regreet = {
    enable = true;

    font = { package = pkgs.noto-fonts; name = "Noto Sans"; size = 13; };
    iconTheme = { package = pkgs.papirus-icon-theme; name = "Papirus-Dark"; };
    # theme / cursorTheme: GTK4's built-in Adwaita (dark) — the CSS does the rest.

    settings = {
      # After the first login, skip the user/session pickers: just avatar + password.
      skip_selection = true;

      background = {
        path = "/var/lib/greeter-theme/background.png";
        fit = "Cover";
      };

      GTK = {
        application_prefer_dark_theme = true;
        cursor_blink = true;
      };

      appearance.greeting_msg = "welcome home <3";

      widget.clock = {
        format = "%H:%M";            # big thin clock (see regreet.css)
        resolution = "1s";
        label_width = 0;
      };
    };

    extraCss = ./regreet.css;
  };

  # Run the greeter in sway (see greeterSway above) instead of the module's default cage.
  services.greetd.settings.default_session.command = lib.mkForce
    "${pkgs.dbus}/bin/dbus-run-session ${config.programs.sway.package}/bin/sway --config ${greeterSway}";

  # Readable by the greeter, writable by you (greeter-sync.sh fills it).
  systemd.tmpfiles.rules = [ "d /var/lib/greeter-theme 0755 mind users -" ];

  # You now log in through greetd instead of the TTY `login`, so unlock
  # gnome-keyring from that password too.
  security.pam.services.greetd.enableGnomeKeyring = true;
}
