# nixos-config

NixOS configuration and dotfiles for `transprideworkload`, a desktop workstation
running sway on Wayland.

<img width="1918" height="1080" alt="image" src="https://github.com/user-attachments/assets/f4585506-1ac4-42e7-8ce0-d12aebda0d43" />

> **Note:** This configuration is a work in progress. There is a lot left to do —
> expect rough edges, missing pieces, and things that only make sense on this
> exact machine. Use it as a reference, not as something to deploy as-is.

## Use case

This machine is a daily-driver desktop workstation used for:

- General desktop use and web browsing
- Software development (C/C++, Rust, Go, .NET, Node)
- Android tooling (adb, fastboot, heimdall)
- Gaming: Steam titles and osu! (stable, via osu-winello) with a
  low-latency focus — high refresh displays, tearing enabled, tuned
  pipewire buffers, and a graphics tablet

## Overview

- **OS:** NixOS (unstable, flakes)
- **WM:** sway
- **Bar:** waybar
- **Launcher:** rofi
- **Terminal:** alacritty (foot as backup)
- **Notifications:** mako
- **Shell:** zsh with oh-my-zsh and powerlevel10k
- **Audio:** pipewire (with low-latency pulse settings)
- **Boot:** systemd-boot, latest kernel

## Hardware

- **Board:** Gigabyte X570 GAMING X
- **CPU:** AMD Ryzen 9 5950X (16c/32t)
- **GPU:** AMD Radeon RX 6600
- **RAM:** 128 GB
- **Disk:** 1 TB (ext4, no swap)
- **Displays:** Acer VG250Q F3 (1080p, 320 Hz) + MSI (1080p, 180 Hz)
- **Input:** graphics tablet via OpenTabletDriver

## Layout

```
nixos-config/
├── configuration.nix           # machine core: boot, networking, user, shell
├── hardware-configuration.nix  # generated hardware scan
├── packages.nix                # system packages and toolchains
├── desktop.nix                 # sway, portals, fonts, theming
├── gaming.nix                  # steam, gamemode, lact, tablet, app compat
└── dotfiles/
    ├── alacritty/              # terminal config
    ├── cava/                   # audio visualizer
    ├── mako/                   # notification styling
    ├── pipewire/               # low-latency pulse drop-in
    ├── rofi/                   # launcher theme
    ├── sway/                   # WM config and keybindings
    ├── waybar/                 # bar modules and styling
    └── zsh/                    # .zshrc and p10k config
```

## Usage

System configuration is applied with:

```
sudo nixos-rebuild switch --flake /etc/nixos#transprideworkload
```

(aliased to `nrs` in the config).

Dotfiles are symlinked from this repository into `~/.config` by hand or with
GNU stow. They are not yet managed declaratively.

## Notable details

- Keybindings use `bindsym --to-code` so they work on both the US and Thai
  keyboard layouts.
- Waybar icons are written as JSON `\u` escape sequences instead of raw glyphs
  so they survive copy-paste.
- Thai text prefers Noto Sans Thai Looped via a user fontconfig rule.
- osu! (stable) is installed through osu-winello, run under `steam-run`
  because of FHS assumptions in its tooling:
  `steam-run ./osu-winello.sh` to install, `steam-run osu-wine` to play.
- `amdgpu.ppfeaturemask` is set to unlock overclocking controls, managed
  through LACT.
- ntsync is enabled for Wine synchronization.

## Known issues and workarounds

Problems I have personally hit on this setup, and how to get around them.

- **osu-wine does not run directly.** Launching `osu-wine` (or the installer
  `./osu-winello.sh`) fails on NixOS because the tooling assumes an FHS
  filesystem (`/bin/true`, `/usr/lib`, etc.). Always run it through steam-run:
  `steam-run ./osu-winello.sh` to install, `steam-run osu-wine` to play.
  `programs.steam.enable` must be on for steam-run to exist.
- **Reboot can hang to a black screen** (X570 firmware quirk). `reboot=efi`
  is set in kernelParams as the workaround.

## TODO

- Coming soon

## License

Do whatever you want with it. Attribution appreciated but not required.
