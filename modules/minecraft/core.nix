{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.minecraftPro;

  renderValue = v:
    if builtins.isBool v then (if v then "true" else "false")
    else toString v;

  propertiesText = attrs:
    concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${renderValue v}") attrs) + "\n";

  # Rendered at build time and stored in the Nix store - safe, because
  # rcon.password is deliberately excluded (see the assertion below).
  propertiesFile = pkgs.writeText "server.properties.base" (propertiesText cfg.serverProperties);
in
{
  options.services.minecraftPro = {
    enable = mkEnableOption "the professional Paper Minecraft server";

    package = mkOption {
      type = types.package;
      description = "Paper server package - see pkgs/paper.nix.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/minecraft-pro";
      description = "Stateful directory: world data, plugin configs/data, logs, backups. Survives rebuilds and upgrades.";
    };

    user = mkOption { type = types.str; default = "minecraft"; };
    group = mkOption { type = types.str; default = "minecraft"; };

    jvmOpts = mkOption {
      type = types.listOf types.str;
      default = [
        "-Xms2048M"
        "-Xmx2048M"
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
      ];
      description = ''
        JVM flags as a list, not a single string - this lets other modules
        (e.g. monitoring.nix's javaagent) append their own flags without
        clobbering yours. Lists merge across modules automatically.
      '';
    };

    serverProperties = mkOption {
      type = types.attrsOf (types.oneOf [ types.str types.int types.bool ]);
      default = { };
      description = ''
        Contents of server.properties, EXCEPT rcon.password - set that via
        services.minecraftPro.rcon.passwordFile instead. Everything in
        here is written into the Nix store, which is world-readable.
      '';
    };

    openFirewall = mkOption { type = types.bool; default = false; };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = !(cfg.serverProperties ? "rcon.password");
        message = ''
          Do not set "rcon.password" in services.minecraftPro.serverProperties -
          it would be written in plaintext to /nix/store, world-readable.
          Use services.minecraftPro.rcon.passwordFile instead.
        '';
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = false; # tmpfiles rule below owns directory creation
    };
    users.groups.${cfg.group} = { };

    networking.firewall.allowedTCPPorts =
      mkIf cfg.openFirewall [ (cfg.serverProperties."server-port" or 25565) ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.dataDir}/plugins 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Other modules (plugins/rcon/backup/security/monitoring) each append
    # to this same service definition. Import order in default.nix is the
    # execution order for preStart fragments: core writes the base
    # server.properties first, then plugins symlinks jars, then rcon
    # substitutes the real password in, etc.
    systemd.services.minecraft-pro = {
      description = "Paper Minecraft server (minecraftPro)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/minecraft-server ${concatStringsSep " " cfg.jvmOpts}";
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStopSec = "60s"; # give the JVM time to flush the world
        KillSignal = "SIGTERM";
      };

      preStart = ''
        echo "eula=true" > "${cfg.dataDir}/eula.txt"
        install -m 0640 ${propertiesFile} "${cfg.dataDir}/server.properties"
      '';
    };
  };
}
