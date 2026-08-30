{ pkgs, lib }:

let
  # A datapack is authored as a Beet (Python) project under
  # datapacks-src/<name>, built out-of-band with `beet build` (see the
  # devShell) - beet isn't packaged in Nix on purpose, same call made for
  # plugins-src: it's a dev-authoring tool, not something that ships to
  # the server, and hand-packaging its Python dependency tree as Nix
  # derivations isn't worth the risk for that. The *build output* folder
  # is what gets committed, exactly like plugins-src/ping/target/*.jar -
  # Nix only ever touches the already-built artifact.
  #
  # srcPath should point at the datapack root beet produced: the folder
  # that directly contains pack.mcmeta and data/. Beet names that folder
  # "<name>_data_pack" by default (the "welcome" project's beet.json has
  # "name": "welcome", so its build output is
  # datapacks-src/welcome/build/welcome_data_pack).
  mkLocalDatapack =
    { name, version, srcPath }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit version;
      src = srcPath;
      dontUnpack = true; # srcPath is already an unpacked directory
      installPhase = ''
        mkdir -p $out/${name}
        cp -r $src/. $out/${name}/
      '';
    };

  # For datapacks distributed as a finished download (Modrinth, a GitHub
  # release, etc.) - same shape as plugins/sources.nix's mkPlugin, but
  # unzipped into a named folder rather than left zipped, since /reload
  # expects a folder (or an unzipped-in-place pack) under
  # world/datapacks, not an opaque archive sitting there unextracted.
  mkDatapack =
    { name, version, url, sha256 }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit version;
      src = pkgs.fetchurl { inherit url sha256; };
      nativeBuildInputs = [ pkgs.unzip ];
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/${name}
        unzip -q $src -d $out/${name}
      '';
    };

in
{
  inherit mkLocalDatapack mkDatapack;

  # Example set - swap in whatever you actually want.
  all = [

    # Uncomment once you've run `beet build` inside datapacks-src/welcome
    # (see the devShell in flake.nix) and committed the resulting
    # build/welcome_data_pack folder it produces:
    #
    # (mkLocalDatapack {
    #   name = "welcome";
    #   version = "1.0";
    #   srcPath = ../datapacks-src/welcome/build/welcome_data_pack;
    # })

  ];
}
