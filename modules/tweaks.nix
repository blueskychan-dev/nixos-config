{ config, lib, pkgs, ... }:

{
# Compressed RAM swap (safety net; no disk swap needed with 128 GB RAM)
zramSwap = {
enable = true;
algorithm = "zstd";
memoryPercent = 25;
};

# Nix build performance
nix.settings = {
max-jobs = "auto";
cores = 0; # use all threads per build
auto-optimise-store = true; # hardlink dedup in /nix/store
};

# Automatic store cleanup
nix.gc = {
automatic = true;
dates = "weekly";
options = "--delete-older-than 14d";
};

# Builds and temp files in RAM
# NOTE: takes effect at next boot. Do not point huge builds (AOSP) at /tmp.
boot.tmp.useTmpfs = true;

# SSD trim
services.fstrim.enable = true;

# Interactivity-first scheduler (sched-ext) — keeps games smooth while compiling
services.scx = {
enable = true;
scheduler = "scx_lavd";
};

# Documentation trims: keep man pages readable, cut the rarely-used rest
documentation.doc.enable = false; # /share/doc files
documentation.info.enable = false; # GNU info pages
documentation.man.cache.enable = false;
}
