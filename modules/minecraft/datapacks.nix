{ config, lib, ... }:

with lib;

let
  cfg = config.services.minecraftPro;

  # Paper writes the world save under <dataDir>/<level-name> (vanilla
  # default "world" if serverProperties doesn't set one) - datapacks
  # live inside *that* folder, not at the top level the way plugin jars
  # sit directly under <dataDir>/plugins.
  levelName = cfg.serverProperties."level-name" or "world";
  datapacksDir = "${cfg.dataDir}/${levelName}/datapacks";
in
{
  options.services.minecraftPro.datapacks = mkOption {
    type = types.listOf types.package;
    default = [ ];
    description = ''
      Datapack derivations - see datapacks/sources.nix's mkLocalDatapack/
      mkDatapack helpers. Each package should contain one or more
      datapack folders (a pack.mcmeta plus a data/ directory) at its top
      level; they get symlinked into <dataDir>/<level-name>/datapacks on
      every service start.

      Unlike plugins, datapacks take effect on world load rather than
      needing a JVM restart - either the very first boot after adding
      one, or immediately via /reload on a running server.
    '';
  };

  config = mkIf (cfg.enable && cfg.datapacks != [ ]) {
    systemd.tmpfiles.rules = [
      "d ${datapacksDir} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.minecraft-pro.preStart = ''
      # Same contract as plugins.nix: drop this generation's symlinks
      # first so a datapack removed from the list actually disappears.
      # A datapack's in-world effects (advancements it granted, scores
      # it set) live in the world save itself and are never touched
      # here - only the pack folder symlink is managed.
      find "${datapacksDir}" -maxdepth 1 -type l -delete

      ${concatMapStringsSep "\n" (pack: ''
        for dp in ${pack}/*/; do
          name="$(basename "$dp")"
          ln -sfn "$dp" "${datapacksDir}/$name"
        done
      '') cfg.datapacks}
    '';
  };
}
