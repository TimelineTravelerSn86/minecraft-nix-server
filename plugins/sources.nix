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

in
{
  inherit mkPlugin;

  # Example set - swap in whatever you actually want.
  # Get each sha256 with: nix-prefetch-url <jar-download-url>
  all = [
    (mkPlugin {
      name = "EssentialsX";
      version = "2.20.1";
      url = "https://github.com/EssentialsX/Essentials/releases/download/2.20.1/EssentialsX-2.20.1.jar";
      sha256 = "0hpm3fk073f2z8aah9l1inq27h9kd60jb2c1grcs8326v85s6bl0";
    })
    # (mkPlugin {
    #   name = "LuckPerms";
    #   version = "5.4.130";
    #   url = "https://github.com/LuckPerms/LuckPerms/releases/download/v5.4.130/LuckPerms-Bukkit-5.4.130.jar";
    #   sha256 = lib.fakeSha256; # REPLACE
    # })

    # Your custom /ping plugin from earlier, once built into a jar:
    # (mkPlugin {
    #   name = "PingCommand";
    #   version = "1.0";
    #   url = "https://github.com/you/ping-plugin/releases/download/v1.0/PingCommand-1.0.jar";
    #   sha256 = lib.fakeSha256; # REPLACE
    # })
  ];
}
