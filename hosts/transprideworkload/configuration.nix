# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./desktop.nix
    ./gaming.nix
    ./virtualisation.nix
  ];

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
    consoleMode = "max";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "ntsync" ];
  boot.kernelParams = [ "reboot=acpi" "amd_iommu=on" "iommu=pt" "amdgpu.ppfeaturemask=0xffffffff" "preempt=full" ];
  boot.blacklistedKernelModules = [ "hid_uclogic" ];

  # Overall performance
  powerManagement.cpuFreqGovernor = "performance";

  # Networking
  networking.hostName = "transprideworkload";
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  # User
  users.users.mind = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/mind";
    extraGroups = [ "wheel" "libvirtd" ];
    packages = with pkgs; [ tree ];
  };

  # Shell
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake /etc/nixos#transprideworkload";
    nixos-edit = "sudo nano /etc/nixos/configuration.nix";
  };

  # Misc programs / services
  programs.firefox.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "mind";
    group = "users";
    dataDir = "/home/mind";               # default folder path
    configDir = "/home/mind/.config/syncthing";
  };

  # Hard Drive Stuff
  fileSystems."/mnt/vms-old" = {
    device = "/dev/disk/by-uuid/aa711881-3ab6-457f-900f-d1082f0ecbd4";
    fsType = "ext4";
    options = [ "noatime" "nofail" ];
  };

  fileSystems."/mnt/hdd-data" = {
    device = "/dev/disk/by-uuid/47d066ac-daac-4656-9179-43847e423cbb";
    fsType = "ext4";
    options = [ "noatime" "nofail" ];
  };

  fileSystems."/mnt/hdd-big-data" = {
    device = "/dev/disk/by-uuid/b9c23c5f-479f-4640-985a-f016ff2ddc48";
    fsType = "ext4";
    options = [ "noatime" "nofail" ];
  };

  # Never change this. Read the manual first if you think you must.
  system.stateVersion = "26.05";
}
