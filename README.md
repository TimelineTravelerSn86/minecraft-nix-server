# minecraft-nix-server

A modular, flake-based Paper Minecraft server for NixOS: declarative
plugins, scheduled backups, systemd sandboxing, and Prometheus monitoring
- each as its own toggleable module. See `docs/ARCHITECTURE.md` for the
full design rationale.

## Quick start

1. **Pin a real Paper build.** Edit `pkgs/paper.nix`'s defaults (or the
   `callPackage` call in `example/configuration.nix`) with a real
   `mcVersion` / `build` / `sha256`. Get the hash with:
   ```
   nix-prefetch-url https://api.papermc.io/v2/projects/paper/versions/<mcVersion>/builds/<build>/downloads/paper-<mcVersion>-<build>.jar
   ```

2. **Fill in plugin hashes.** Every `sha256 = lib.fakeSha256;` in
   `plugins/sources.nix` needs a real hash from `nix-prefetch-url`, or
   swap in the plugins you actually want.

3. **Set up the RCON secret.** This project refuses to let you put the
   RCON password in `serverProperties` (it would land in the world-
   readable Nix store). Using agenix:
   ```
   nix run github:ryantm/agenix -- -e secrets/rcon-password.age
   ```
   and point `age.secrets.mc-rcon-password.file` at it, as shown in
   `example/configuration.nix`. No agenix? Any file readable only by the
   `minecraft` user works - just set `rcon.passwordFile` to its path.

4. **Import the module** in your NixOS config:
   ```nix
   {
     inputs.minecraft-nix-server.url = "path:/etc/nixos/minecraft-nix-server";
     # or a git URL once you push this somewhere
   }
   ```
   then add `minecraft-nix-server.nixosModules.minecraftPro` to your
   host's `modules`, and copy/adapt `example/configuration.nix`.

5. **Build and switch:**
   ```
   nixos-rebuild switch --flake .#yourHost
   ```

6. **Admin from the command line:**
   ```
   mc-console list
   mc-console say "back in 5"
   ```

## Layout

```
flake.nix                        entry point
modules/minecraft/               one file per concern (see ARCHITECTURE.md)
pkgs/paper.nix                   the server package itself
plugins/sources.nix              mkPlugin helper + your plugin list
example/configuration.nix        a full worked example host
docs/ARCHITECTURE.md             design decisions and upgrade guides
```

## Sanity-check before deploying

```
nix flake check
nixos-rebuild build-vm --flake .#exampleHost   # boots a throwaway VM
```
