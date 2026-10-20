{ pkgs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "martinsedd" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  zramSwap.enable = true;

  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs.root = {
      SUBVOLUME = "/";
      ALLOW_USERS = [ "martinsedd" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 5;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 6;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    snapper
    (writeShellScriptBin "pre-build-snapshot" ''
      exec ${snapper}/bin/snapper -c root create \
        --description "pre-build $(date -u +%Y%m%dT%H%M%SZ)" \
        --userdata important=yes 
    '')
  ];
}
