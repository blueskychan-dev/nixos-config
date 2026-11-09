{ config, lib, pkgs, ... }:
{
  # Sunshine: self-hosted game-stream host, pair with the Moonlight client.
  # Web UI: https://localhost:47990 (set a username/password on first visit).
  services.sunshine = {
    enable = false;
    autoStart = false;      # user service, starts with graphical-session.target
    openFirewall = true;   # 47984-47990 TCP, 47998-48010 UDP
    capSysAdmin = true;    # needed for DRM/KMS capture (fallback when the
                           # wlroots dmabuf export path is unavailable)
  };

  # Virtual gamepad / keyboard / mouse from the client go through uinput.
  users.users.mind.extraGroups = [ "uinput" ];
}
