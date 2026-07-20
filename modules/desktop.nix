{ config, lib, pkgs, ... }:
{
  # Sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock swayidle wl-clipboard mako waybar
      alacritty foot
      rofi nemo grim slurp
      swaybg cava pavucontrol
    ];
  };

  # Portals
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Theming
  environment.systemPackages = with pkgs; [
    adw-gtk3 papirus-icon-theme
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
