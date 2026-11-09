{ config, lib, pkgs, ... }:
# Qt theming + media apps.
{
  # Qt/KDE apps (Ark, …) follow the same Catppuccin Mocha peach look as GTK.
  #   style    -> Kvantum, theme "catppuccin-mocha-peach" (~/.config/Kvantum/)
  #   platform -> qt5ct/qt6ct, icons Papirus-Dark (~/.config/qt5ct, ~/.config/qt6ct)
  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };

  environment.systemPackages = with pkgs; [
    # Video: mpv with a minimal modern UI (uosc), seek-bar thumbnails (thumbfast)
    # and MPRIS so waybar / the lock screen / media keys see it.
    # Config: ~/.config/mpv/mpv.conf, ~/.config/mpv/script-opts/uosc.conf
    (mpv.override { scripts = with mpvScripts; [ uosc thumbfast mpris ]; })
    # Images: GNOME's Loupe (GTK4, follows ~/.config/gtk-4.0/gtk.css)
    loupe
  ];
}
