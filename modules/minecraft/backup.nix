{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.minecraftPro;
  bcfg = cfg.backup;

  backupScript = pkgs.writeShellApplication {
    name = "mc-backup";
    runtimeInputs = [
      pkgs.mcrcon
      pkgs.gnutar
      pkgs.gzip
      pkgs.findutils
    ];
    text = ''
      set -euo pipefail
      ts="$(date +%Y%m%d-%H%M%S)"
      dest="${bcfg.destination}"
      mkdir -p "$dest"

      pw="$(cat ${cfg.rcon.passwordFile})"
      rcon() { mcrcon -H 127.0.0.1 -P ${toString cfg.rcon.port} -p "$pw" "$@"; }

      rcon save-off
      rcon save-all
      sync

      tar -C "${cfg.dataDir}" --exclude='backups' -czf "$dest/world-$ts.tar.gz" .

      rcon save-on

      # Retention: keep only the newest N snapshots.
      cd "$dest"
      ls -1t world-*.tar.gz 2>/dev/null | tail -n +$(( ${toString bcfg.retention} + 1 )) | xargs -r rm --
    '';
  };
in
{
  options.services.minecraftPro.backup = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    schedule = mkOption {
      type = types.str;
      default = "03:30";
      description = "systemd OnCalendar expression, e.g. \"03:30\" or \"Sun 04:00\".";
    };

    destination = mkOption {
      type = types.path;
      default = "/var/backup/minecraft-pro";
    };

    retention = mkOption {
      type = types.int;
      default = 7;
      description = "How many snapshots to keep before older ones are deleted.";
    };
  };

  config = mkIf (cfg.enable && bcfg.enable) {

    assertions = [
      {
        assertion = cfg.rcon.enable;
        message = "services.minecraftPro.backup needs rcon.enable = true (used for save-off/save-on around each snapshot).";
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${bcfg.destination} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.minecraft-pro-backup = {
      description = "Snapshot the minecraftPro world directory";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${backupScript}/bin/mc-backup";
      };
    };

    systemd.timers.minecraft-pro-backup = {
      description = "Scheduled backups for minecraftPro";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = bcfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
