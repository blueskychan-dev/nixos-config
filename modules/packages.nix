{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # basics
    vim wget git unzip zenity
    fastfetch hyfetch pay-respects lm_sensors telegram-desktop
    qt6.qtwayland qt5.qtwayland usbutils pciutils btop vscodium neovim vesktop
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
    android-tools heimdall
  ];
}
