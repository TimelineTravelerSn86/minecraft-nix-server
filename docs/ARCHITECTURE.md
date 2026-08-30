# Architecture

## Layers

```
flake.nix                       <- pins nixpkgs + agenix, exposes the module
  └─ modules/minecraft/
       default.nix               <- aggregator, no logic
       core.nix                  <- package, user, systemd unit, server.properties
       plugins.nix                <- declarative jar list -> symlinks
       rcon.nix                   <- rcon config + secret injection + admin CLI
       backup.nix                 <- scheduled snapshots (save-off/all/on)
       security.nix                <- systemd sandboxing
       monitoring.nix               <- JMX exporter + healthcheck timer
  └─ pkgs/paper.nix              <- versioned Paper server derivation
  └─ plugins/sources.nix         <- mkPlugin helper + your plugin list
  └─ example/configuration.nix   <- a full host wiring everything together
```

Each concern is its own NixOS module file. `default.nix` just imports them;
it owns no options and no config. Any module can be deleted without
breaking the others - `plugins.nix` doesn't know `backup.nix` exists.

## Why this shape

**One systemd unit, many contributors.** `core.nix` defines the
`minecraft-pro` systemd service. `rcon.nix`, `plugins.nix`, `security.nix`,
and `monitoring.nix` each *extend* that same unit (its `preStart`,
`serviceConfig`, or `jvmOpts`) rather than defining their own services.
NixOS's module system merges these automatically - `jvmOpts` is a
`listOf str` specifically so monitoring's `-javaagent` flag appends
instead of clobbering your GC flags.

**Ordering contract.** `preStart` fragments concatenate in the order
modules are imported in `default.nix`: core writes the base
`server.properties` first, then plugins symlinks jars, then rcon appends
the real password. If you add a module that also touches `preStart` and
ordering matters, add it to that import list in the position it needs.

**Secrets never touch the Nix store.** The original config had
`"rcon.password" = "viper"` sitting in `serverProperties` - that gets
written into `/nix/store`, which is world-readable on the machine. This
setup asserts against that (see `core.nix`'s `assertions`) and instead
takes `rcon.passwordFile`, a path to a secret decrypted at activation time
(agenix, sops-nix, or even a manually-placed root-only file). The
password is spliced into `server.properties` at service start via `sed`,
never baked into a derivation.

**Plugins are symlinks, not copies.** Plugin jars live in the Nix store
(immutable, content-addressed, easy to pin with `nix-prefetch-url`).
`plugins.nix` symlinks them into `<dataDir>/plugins` on every start and
deletes stale symlinks from previous generations - but it only ever
touches symlinks. A plugin's own generated config folder
(`plugins/EssentialsX/config.yml`, etc.) is real state that Nix never
sees, so your plugin settings survive every rebuild.

**Security hardening is a systemd concern, not a JVM one.** `security.nix`
sandboxes the *process* (no new privileges, read-only filesystem outside
`dataDir`, restricted syscalls, no raw capabilities) rather than trying to
harden Minecraft itself. One deliberate exception:
`MemoryDenyWriteExecute = false` - the JVM's JIT needs executable memory
pages at runtime, and turning this on will just break startup.

**Backups wrap RCON's save-off/save-on.** Copying world files while the
server is actively writing to region files risks corruption. The backup
script disables autosave, forces a flush, tars the directory, and
re-enables autosave - all before touching the tarball.

**Monitoring is opt-in and additive.** The JMX Prometheus exporter is
attached as a `-javaagent` flag (appended to `jvmOpts`, doesn't replace
your GC tuning). A separate lightweight healthcheck timer pings the
server over RCON every 2 minutes and can hit a webhook on failure -
useful even without a full Prometheus/Grafana stack.

## Upgrading Paper

1. Check https://papermc.io/downloads/paper for the Minecraft version you
   want and its latest build number.
2. `nix-prefetch-url <the .jar download URL>` for the sha256.
3. Update `mcVersion`, `build`, and `sha256` wherever you call
   `pkgs/paper.nix` (see `example/configuration.nix`).
4. `nixos-rebuild switch` - the service restarts on the new jar, your
   `dataDir` (world, plugin configs, backups) is untouched.

## Adding a plugin

1. Find the plugin's jar download URL (Modrinth, Spigot, or its GitHub
   releases).
2. `nix-prefetch-url <url>` for the sha256.
3. Add a `mkPlugin { ... }` entry in `plugins/sources.nix`.
4. `nixos-rebuild switch` - the jar gets symlinked in and the plugin
   loads on the next server start. Its generated config folder appears
   under `<dataDir>/plugins/<Name>/` on first run and is yours to edit
   directly; Nix won't touch it again.

## What to harden further, if you want to go past this

- Swap the `sed`-based password injection for systemd's `LoadCredential=`,
  which avoids ever writing the plaintext password to a file the server
  process can read beyond its own lifetime.
- Ship backups off-box (rsync/restic to a remote target) instead of only
  `/var/backup` on the same disk - a disk failure currently takes out
  both the live world and its backups.
- Add `systemd-notify`/`Type=notify` support if you want systemd to know
  precisely when the server has finished starting, rather than assuming
  `Type=simple` is good enough.
