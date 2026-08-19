{ config, lib, pkgs, ... }:
{
  # Sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock-effects swayidle wl-clipboard mako waybar
      alacritty foot
      rofi nemo grim slurp
      swaybg cava pavucontrol wayfreeze
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
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
  };

 xdg.portal.config = {
   common.default = [ "gtk" ];
   sway = {
     default = [ "gtk" ];
     "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
     "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
   };
 };

  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # XDG user directories.
  # Sway pulls in no DE module, so nothing was generating ~/.config/user-dirs.dirs.
  # Flatpak resolves filesystem permissions like xdg-download / xdg-pictures through
  # that file (glib's g_get_user_special_dir). When it is missing they resolve to
  # nothing and get silently dropped, so sandboxed apps see no host dirs at all.
  systemd.packages = [ pkgs.xdg-user-dirs ];
  systemd.user.services.xdg-user-dirs.wantedBy = [ "graphical-session-pre.target" ];

  # Theming
  environment.systemPackages = with pkgs; [
    adw-gtk3 papirus-icon-theme
    xdg-user-dirs xdg-utils
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
