{ pkgs, lib }:

let
  mkPlugin =
    {
      name,
      version,
      url,
      sha256,
    }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit version;
      src = pkgs.fetchurl { inherit url sha256; };
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out
        cp $src $out/${name}-${version}.jar
      '';
    };
  mkLocalPlugin =
    {
      name,
      version,
      srcPath,
    }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit version;
      src = srcPath;
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out
        cp $src $out/${name}-${version}.jar
      '';
    };

in
{
  inherit mkPlugin mkLocalPlugin;

  # Example set - swap in whatever you actually want.
  # Get each sha256 with: nix-prefetch-url <jar-download-url>
  all = [

    (mkLocalPlugin {
      name = "Ping";
      version = "1.0";
      srcPath = ../plugins-src/ping/target/ping-plugin-1.0.jar;
    })

    (mkPlugin {
      name = "VoiceChat";
      version = "2.6.21";
      url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/62MVmInV/voicechat-bukkit-2.6.21.jar";
      sha256 = "1n4lkckwyggp750dmxqrqhzf8mx3wabwh4qvi185bv0r1ivlb0f0";
    })
    (mkPlugin {
      name = "Plan";
      version = "5.8-build-3605";
      url = "https://cdn.modrinth.com/data/wJQfHhxh/versions/VCtXebje/Plan-5.8-build-3605.jar";
      sha256 = "0p0hkbpw07kkzq314lx7z12n0k7cnlzdadraxfnd5mqdj43bh77n";
    })
    (mkPlugin {
      name = "CoreProtect";
      version = "24.0";
      url = "https://cdn.modrinth.com/data/Lu3KuzdV/versions/Kma0kBsY/CoreProtect-CE-24.0.jar";
      sha256 = "15jn85h8v9s3l3qxb42mwv4hvgrknklpgvhql3jk115vi4h3dkb6";
    })
    (mkPlugin {
      name = "PlayerStats";
      version = "1.3";
      url = "https://cdn.modrinth.com/data/ONtvwRCv/versions/8ng9KjEE/PlayerStats.jar";
      sha256 = "0w88cbv5cq7sabbbahh7g7fhh5zi62p3m26iwgir8yd9smq0xpn1";
    })
    (mkPlugin {
      name = "DiscordSRV";
      version = "1.30.5";
      url = "https://cdn.modrinth.com/data/UmLGoGij/versions/ATlquwiT/DiscordSRV-Build-1.30.5.jar";
      sha256 = "1vzgi965afbp812zx0r6528zrw9kvnkr0w9b85vpqv0lxgra2bzg";
    })

    # Your custom /ping plugin from earlier, once built into a jar:
    # (mkPlugin {
    #   name = "PingCommand";
    #   version = "1.0";
    #   url = "https://github.com/you/ping-plugin/releases/download/v1.0/PingCommand-1.0.jar";
    #   sha256 = lib.fakeSha256; # REPLACE
    # })
  ];
}
