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

    # Your custom /ping plugin from earlier, once built into a jar:
    # (mkPlugin {
    #   name = "PingCommand";
    #   version = "1.0";
    #   url = "https://github.com/you/ping-plugin/releases/download/v1.0/PingCommand-1.0.jar";
    #   sha256 = lib.fakeSha256; # REPLACE
    # })
  ];
}
