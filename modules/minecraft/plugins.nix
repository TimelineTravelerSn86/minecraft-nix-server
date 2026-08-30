{ config, lib, ... }:

with lib;

let
  cfg = config.services.minecraftPro;
in
{
  options.services.minecraftPro.plugins = mkOption {
    type = types.listOf types.package;
    default = [ ];
    description = ''
      Plugin jar derivations - see plugins/sources.nix's mkPlugin helper.
      Each package should contain one or more .jar files at its top level;
      they get symlinked into <dataDir>/plugins on every service start.

      Only the jar symlinks are managed - a plugin's own generated config
      folder under <dataDir>/plugins/<Name>/ is real state and is never
      touched, so plugin settings survive rebuilds.
    '';
  };

  config = mkIf (cfg.enable && cfg.plugins != [ ]) {
    systemd.services.minecraft-pro.preStart = ''
      # Drop symlinks from the previous generation first, so a plugin you
      # removed from the list actually disappears. Real files/directories
      # (plugin data, plugin config) are untouched - only symlinks here.
      find "${cfg.dataDir}/plugins" -maxdepth 1 -type l -delete

      ${concatMapStringsSep "\n" (plugin: ''
        for jar in ${plugin}/*.jar; do
          ln -sf "$jar" "${cfg.dataDir}/plugins/$(basename "$jar")"
        done
      '') cfg.plugins}
    '';
  };
}
