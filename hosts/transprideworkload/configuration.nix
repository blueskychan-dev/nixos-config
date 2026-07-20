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
  boot.kernelParams = [ "reboot=efi" "amd_iommu=on" "iommu=pt" "amdgpu.ppfeaturemask=0xffffffff" "preempt=full" ];
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
  };

  # User
  users.users.mind = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/mind";
    extraGroups = [ "wheel" ];
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

  # Never change this. Read the manual first if you think you must.
  system.stateVersion = "26.05";
}
