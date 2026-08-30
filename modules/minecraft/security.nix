{ config, lib, ... }:

with lib;

let
  cfg = config.services.minecraftPro;
in
{
  options.services.minecraftPro.security.hardened = mkOption {
    type = types.bool;
    default = true;
    description = "Apply systemd process sandboxing to the server unit.";
  };

  config = mkIf (cfg.enable && cfg.security.hardened) {
    systemd.services.minecraft-pro.serviceConfig = {
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      RemoveIPC = true;
      CapabilityBoundingSet = "";
      SystemCallFilter = [
        "@system-service"
        "~@resources"
        "perf_event_open"
      ];
      SystemCallArchitectures = "native";

      # Named for the opposite of what we want here on purpose: the JVM's
      # JIT needs to mmap executable pages at runtime, so this stays off -
      # enabling it breaks server startup.
      MemoryDenyWriteExecute = false;

      # The only path outside strict-ProtectSystem the process may write to.
      ReadWritePaths = [ cfg.dataDir ];
    };
  };
}
