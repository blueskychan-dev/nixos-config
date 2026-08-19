{ config, lib, pkgs, ... }:
{
  # Graphics (32-bit needed for Wine / Steam)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Tablet (osu!)
  hardware.opentabletdriver.enable = true;

  # AMDGPU overclock daemon + GUI
  # (needs amdgpu.ppfeaturemask kernel param, set in configuration.nix)
  services.lact.enable = true;

  # Steam for Steam games, gamemode for performance.
  # steam also provides steam-run (FHS env) — needed for osu-winello:
  #   install: steam-run ./osu-winello.sh
  #   play:    steam-run osu-wine
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # Realtime audio (realtimeconfigquickscan fixes)
  boot.kernel.sysctl."vm.swappiness" = 10;

  # SMT off — only if you actually hit DSP spikes; halves logical cores,
  # which you may not want on a gaming box
  # boot.kernelParams = [ "nosmt" ];

  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];
  users.users.mind.extraGroups = [ "audio" ];

  # App compat
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  services.flatpak.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # add missing dynamic libs for unpackaged programs here
  ];
}
