{ config, lib, pkgs, ... }:
{
  # --- Host tools ESP-IDF's install.sh / idf.py expect on PATH ---------------
  environment.systemPackages = with pkgs; [
    python3          # install.sh builds its venv from this
    cmake ninja ccache
    git wget
    flex bison gperf
    dfu-util libusb1
    minicom picocom  # serial monitors (idf.py monitor is the usual one)
  ];

  # --- Let Espressif's PREBUILT toolchain binaries run on NixOS -------------
  # xtensa-esp-elf-gcc, riscv32-esp-elf-gdb, openocd-esp32 and esp-clang are
  # generic FHS binaries. nix-ld (already enabled) provides the /lib64 loader;
  # these are the shared libraries they then link/dlopen against.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib   # libstdc++.so.6, libgcc_s.so.1
    zlib               # gcc, clangd
    libusb1            # openocd, esptool USB-JTAG
    systemd            # libudev.so.1  -> openocd
    ncurses5           # libtinfo.so.5 -> esp-gdb
    ncurses            # libtinfo.so.6
    libxml2            # esp-clang / clangd
    openssl
    libffi
    python3            # libpython3.x.so -> esp-gdb is built with Python support
    util-linux         # libuuid
    glibc
  ];

  # --- Serial port + USB-JTAG access ---------------------------------------
  users.users.mind.extraGroups = [ "dialout" ];

  services.udev.extraRules = ''
    # Silicon Labs CP210x  (most ESP32 DevKitC / NodeMCU boards)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", GROUP="dialout", MODE="0660", TAG+="uaccess"
    # WCH CH340 / CH341    (cheap clone boards)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", GROUP="dialout", MODE="0660", TAG+="uaccess"
    # FTDI FT232/FT2232    (ESP-WROVER-KIT, JTAG adapters)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", GROUP="dialout", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", GROUP="dialout", MODE="0660", TAG+="uaccess"
    # Espressif built-in USB-Serial/JTAG (ESP32-S2/S3/C3/C6/H2) - needs raw USB
    SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", GROUP="dialout", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", GROUP="dialout", MODE="0660", TAG+="uaccess"
  '';
}
