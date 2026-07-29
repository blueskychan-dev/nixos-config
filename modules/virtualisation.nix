{ config, lib, pkgs, ... }:

{
  # KVM/QEMU via libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;              # TPM emulation (Windows 11 wants it)
    };
  };

  # Distrobox stuff
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # GUI manager
  programs.virt-manager.enable = true;

  # SPICE USB redirection (pass USB devices to VMs from virt-manager)
  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    virtiofsd          # shared folders host<->guest
    distrobox
  ];
}
