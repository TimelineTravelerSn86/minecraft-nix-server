{ config, pkgs, ... }:

{
  # Decrypted at activation to /run/agenix/mc-rcon-password, owned by the
  # minecraft user. Create the encrypted file with:
  #   agenix -e secrets/rcon-password.age
  age.secrets.mc-rcon-password = {
    file = ../secrets/rcon-password.age;
    owner = "minecraft";
  };

  services.minecraftPro = {
    enable = true;

    package = pkgs.callPackage ../pkgs/paper.nix {
      mcVersion = "26.2"; # Your desiered Version
      build = "119"; # Your desiered build
      sha256 = "REPLACE ME"; # nix-prefetch-url the paper jar download URL
    };

    openFirewall = true;

    serverProperties = {
      server-port = 25565;
      difficulty = "hard";
      gamemode = "survival";
      max-players = 10;
      motd = "NixOS Minecraft - now with plugins!";
      white-list = true;
      online-mode = true;
    };

    plugins =
      (import ../plugins/sources.nix {
        inherit pkgs;
        inherit (pkgs) lib;
      }).all;

    datapacks =
      (import ../datapacks/sources.nix {
        inherit pkgs;
        inherit (pkgs) lib;
      }).all;

    rcon = {
      enable = true;
      passwordFile = config.age.secrets.mc-rcon-password.path;
    };

    backup = {
      enable = true;
      schedule = "03:30";
      retention = 14;
      destination = "/var/backup/minecraft-pro";
    };

    security.hardened = true;

    monitoring = {
      enable = true;
      exporterPort = 9225;
      # alertWebhookFile = config.age.secrets.mc-alert-webhook.path;
    };
  };
}
