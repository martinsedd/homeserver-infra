{ pkgs, ... }:
{
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/eef33075-3a0f-4945-a46c-4754e4577833";
    fsType = "auto";
    options = [
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=5m"
    ];
  };

  environment.systemPackages = [
    pkgs.restic
    pkgs.sqlite
  ];

  systemd.services.restic-backup = {
    description = "restic backup to external drive";
    after = [ "k3s.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RequiresMountsFor = "/mnt/backup";
      ExecStart = pkgs.writeShellScript "restic-backup" ''
        set -eu 
        export RESTIC_REPOSITORY=/mnt/backup/restic 
        export RESTIC_PASSWORD_FILE=/var/lib/restic/password 

        ${pkgs.sqlite}/bin/sqlite3 /var/lib/rancher/k3s/server/db/state.db \
          ".backup '/var/lib/restic/k3s-state.db'"

        ${pkgs.restic}/bin/restic snapshots >/dev/null 2>&1 \
          || ${pkgs.restic}/bin/restic init 

        ${pkgs.restic}/bin/restic backup \
          --exclude /var/lib/rancher/k3s/agent \
          --exclude /var/lib/rancher/k3s/server/db \
          --tag nightly \
          /home /etc /var/lib/rancher/k3s /var/lib/restic/k3s-state.db

        ${pkgs.restic}/bin/restic forget \
          --keep-daily 7 --keep-weekly 4 --keep-monthly 6 \
          --prune --tag nightly 
      '';
    };
  };

  systemd.timers.restic-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:30";
      Persistent = true;
      RandomizeDelaySec = "10m";
    };
  };
}
