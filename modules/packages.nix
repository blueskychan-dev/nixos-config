{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # basics
    vim wget git unzip zenity
    fastfetch hyfetch pay-respects lm_sensors discord
    # thumbnails (video/images) for the KDE file picker
    kdePackages.kio-extras kdePackages.ffmpegthumbs kdePackages.kdegraphics-thumbnailers
    # Telegram: use the xdg portal file picker instead of Qt's built-in one
    (symlinkJoin {
      name = "telegram-desktop-portal";
      paths = [ telegram-desktop ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/Telegram --set QT_QPA_PLATFORMTHEME xdgdesktopportal
        # D-Bus activation (relaunch after crash, notifications) must also use the wrapper
        svc=$out/share/dbus-1/services/org.telegram.desktop.service
        if [ -e "$svc" ]; then
          sed "s|^Exec=.*|Exec=$out/bin/Telegram|" "$(readlink -f "$svc")" > svc.tmp
          rm "$svc" && mv svc.tmp "$svc"
        fi
      '';
    })
    qt6.qtwayland qt5.qtwayland usbutils pciutils btop vscodium neovim vesktop boinc bubblewrap signal-desktop kdePackages.ark ripgrep tmux weston mangohud libglvnd
    # C/C++
    gcc gnumake cmake pkg-config gdb
    # Rust
    rustc cargo clippy rustfmt rust-analyzer
    # Go
    go
    # .NET
    dotnet-sdk_8
    # Node
    nodejs_22 yarn
    # Android
    android-tools heimdall android-studio
    # Music — local: amberol · Spotify: spotify / spotify_player (TUI) · YouTube Music: pear-desktop
    amberol spotify spotify-player pear-desktop playerctl
    # Terminal: menus (lab/net) + eye candy (clock, matrix, bonsai, pipes)
    fzf tty-clock cmatrix cbonsai pipes lolcat
    # Desktop extras: clipboard history, volume OSD, night light,
    # lock screen + image tools used by ~/.config/sway scripts
    cliphist swayosd wlsunset hyprlock imagemagick
    # AI
    # opencode
  ];
}
