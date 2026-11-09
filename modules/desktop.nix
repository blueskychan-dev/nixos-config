{ config, lib, pkgs, ... }:
{
  imports = [
    ./greeter.nix   # login screen (greetd + ReGreet)
    ./files.nix     # Nemo: trash, USB/phone mounts, thumbnails
    ./look.nix      # Qt theme (Kvantum) + mpv / Loupe
  ];

  # Sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock-effects swayidle wl-clipboard mako waybar
      alacritty foot
      rofi nemo-with-extensions grim slurp
      swaybg cava pavucontrol wayfreeze bemenu wofi fuzzel
    ];
  };

  # Portals
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings.screencast = {
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
	force_mod_linear = 1;
	max_fps = 60;
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

 xdg.portal.config = {
   common.default = [ "gtk" ];
   sway = {
     default = [ "gtk" ];
     "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
     "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
     "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
   };
 };

  # KDE file picker on sway: needs the Plasma platform theme or it falls back to plain QFileDialog
  systemd.user.services.plasma-xdg-desktop-portal-kde = {
    overrideStrategy = "asDropin";
    environment.QT_QPA_PLATFORMTHEME = "kde";
  };

  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Bluetooth (adapter hci0) + blueman tray/manager for the waybar button
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # XDG user directories.
  # Sway pulls in no DE module, so nothing was generating ~/.config/user-dirs.dirs.
  # Flatpak resolves filesystem permissions like xdg-download / xdg-pictures through
  # that file (glib's g_get_user_special_dir). When it is missing they resolve to
  # nothing and get silently dropped, so sandboxed apps see no host dirs at all.
  systemd.packages = [ pkgs.xdg-user-dirs ];
  systemd.user.services.xdg-user-dirs.wantedBy = [ "graphical-session-pre.target" ];

  # Theming
  environment.systemPackages = with pkgs; [
    kdePackages.plasma-integration  # KDE platform theme for the file picker portal
    adw-gtk3 papirus-icon-theme
    xdg-user-dirs xdg-utils

    slurp grim wl-clipboard
    rofi # Note: use rofi-wayland instead of pkgs.rofi on Wayland
    wofi bemenu fuzzel
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.comic-shanns-mono
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];
}
