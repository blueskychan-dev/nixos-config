# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/packages.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/virtualisation.nix
    ../../modules/incus.nix
    ../../modules/tweaks.nix
    ../../modules/wireguard.nix
    ../../modules/sunshine.nix
    ../../modules/esp-idf.nix
  ];

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 3;
    consoleMode = "max";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  environment.systemPackages = [ pkgs.sbctl ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "ntsync" ];
  boot.kernelParams = [ "reboot=acpi" "amd_iommu=on" "iommu=pt" "amdgpu.ppfeaturemask=0xffffffff" "preempt=full" "kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0" "kvm_amd.avic=1"];
  boot.blacklistedKernelModules = [ "hid_uclogic" ];
  boot.supportedFilesystems = [ "f2fs" ];

  # Overall performance
  powerManagement.cpuFreqGovernor = "performance";

  # Networking
  networking.hostName = "mizukioverflow";
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio
  security.rtkit.enable = true; # this is required for pipewire real-time access
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    audio.enable = true;
    alsa = {
        enable = true;
        support32Bit = true;
      };
  };

  # User
  users.users.mind = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/mind";
    extraGroups = [ "wheel" "libvirtd" "incus-admin" ];   # incus-admin: use incus without sudo
    packages = with pkgs; [ tree prismlauncher ];
  };

  # Shell
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  environment.shellAliases = {
    nrs = "(cd /etc/nixos && sudo git add -A && sudo nix flake update && sudo nixos-rebuild switch --flake .#mizukioverflow)";   # git add: flakes only see tracked files
    nixos-edit = "sudo nano /etc/nixos/configuration.nix";
  };

  # Misc programs / services
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.firefox.enable = true;
  programs.nix-ld.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "mind";
    group = "users";
    dataDir = "/home/mind";               # default folder path
    configDir = "/home/mind/.config/syncthing";
  };

  services.boinc = {
    enable = true;
  };

  # Hard Drive Stuff

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
