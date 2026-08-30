{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.minecraftPro;

  mcConsole = pkgs.writeShellApplication {
    name = "mc-console";
    runtimeInputs = [ pkgs.mcrcon ];
    text = ''
      pw="$(cat ${escapeShellArg (toString cfg.rcon.passwordFile)})"
      exec mcrcon -H 127.0.0.1 -P ${toString cfg.rcon.port} -p "$pw" "$@"
    '';
  };
in
{
  options.services.minecraftPro.rcon = {
    enable = mkOption { type = types.bool; default = true; };

    port = mkOption { type = types.port; default = 25575; };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing the RCON password (e.g. an agenix or
        sops-nix secret, decrypted at activation to /run/agenix/...).
        Required when rcon.enable is true. Never put the password directly
        in serverProperties - that lands in the world-readable Nix store.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.rcon.enable) {

    assertions = [
      {
        assertion = cfg.rcon.passwordFile != null;
        message = "services.minecraftPro.rcon.enable is true but rcon.passwordFile is unset.";
      }
    ];

    services.minecraftPro.serverProperties = {
      "enable-rcon" = true;
      "rcon.port" = cfg.rcon.port;
    };

    systemd.services.minecraft-pro.preStart = ''
      rcon_pw="$(cat ${cfg.rcon.passwordFile})"
      sed -i '/^rcon\.password=/d' "${cfg.dataDir}/server.properties"
      echo "rcon.password=$rcon_pw" >> "${cfg.dataDir}/server.properties"
    '';

    # So "mc-console list" / "mc-console say hi" work from any shell.
    environment.systemPackages = [ mcConsole ];
  };
}
