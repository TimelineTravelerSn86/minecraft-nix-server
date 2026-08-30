{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.minecraftPro;
  mcfg = cfg.monitoring;

  jmxExporterJar = pkgs.fetchurl {
    url = "https://github.com/prometheus/jmx_exporter/releases/download/1.1.0/jmx_prometheus_javaagent-1.1.0.jar";
    sha256 = lib.fakeSha256; # REPLACE - nix-prefetch-url the release asset
  };

  jmxExporterConfig = pkgs.writeText "jmx-exporter.yml" ''
    rules:
      - pattern: ".*"
  '';

  healthcheck = pkgs.writeShellApplication {
    name = "mc-healthcheck";
    runtimeInputs = [
      pkgs.mcrcon
      pkgs.curl
    ];
    text = ''
      set -euo pipefail
      pw="$(cat ${cfg.rcon.passwordFile})"
      if ! mcrcon -H 127.0.0.1 -P ${toString cfg.rcon.port} -p "$pw" -t 5 list >/dev/null; then
        echo "minecraft-pro: healthcheck failed" >&2
        ${optionalString (mcfg.alertWebhookFile != null) ''
          hook="$(cat ${mcfg.alertWebhookFile})"
          curl -fsS -X POST -H 'Content-Type: application/json' \
            -d '{"content":"minecraft-pro server is unreachable"}' "$hook" || true
        ''}
        exit 1
      fi
    '';
  };
in
{
  options.services.minecraftPro.monitoring = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    exporterPort = mkOption {
      type = types.port;
      default = 9225;
    };

    alertWebhookFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "File containing a Discord/ntfy/Slack webhook URL, notified when the healthcheck fails.";
    };
  };

  config = mkIf (cfg.enable && mcfg.enable) {

    assertions = [
      {
        assertion = cfg.rcon.enable;
        message = "services.minecraftPro.monitoring needs rcon.enable = true (the healthcheck uses RCON).";
      }
    ];

    # Appends to core.nix's jvmOpts list rather than replacing it.
    services.minecraftPro.jvmOpts = [
      "-javaagent:${jmxExporterJar}=${toString mcfg.exporterPort}:${jmxExporterConfig}"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ mcfg.exporterPort ];

    systemd.services.minecraft-pro-healthcheck = {
      description = "Healthcheck for minecraftPro";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${healthcheck}/bin/mc-healthcheck";
      };
    };

    systemd.timers.minecraft-pro-healthcheck = {
      description = "Periodic healthcheck for minecraftPro";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnUnitActiveSec = "2m";
        OnBootSec = "2m";
      };
    };
  };
}
