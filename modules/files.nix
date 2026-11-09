{ config, lib, pkgs, ... }:
# File manager (Nemo) plumbing for a plain sway session — the pieces a full
# desktop environment would normally pull in for you.
{
  # Trash, MTP (phones), network shares (smb/sftp), "Computer"/"Network" views.
  services.gvfs.enable = true;
  # Mount USB drives / SD cards from Nemo's sidebar without root.
  services.udisks2.enable = true;

  # Thumbnails: Nemo uses gdk-pixbuf for images + /share/thumbnailers for the rest.
  programs.gdk-pixbuf.modulePackages = [
    pkgs.webp-pixbuf-loader   # .webp  (lots of these in ~/Pictures)
    pkgs.libheif.lib          # .heic / .avif (phone photos) — loader lives in the "lib" output
  ];

  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer         # video thumbnails
    file-roller               # backend for Nemo's "Extract here" / "Compress…"
  ];
}
