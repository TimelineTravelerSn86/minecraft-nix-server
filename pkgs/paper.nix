{
  lib,
  stdenv,
  fetchurl,
  jdk25_headless,
  # Bump these three values to upgrade. Get the build number and hash from:
  #   curl https://api.papermc.io/v2/projects/paper/versions/<mcVersion>
  #   nix-prefetch-url <download-url>   # for the sha256
  mcVersion ? "26.2",
  build ? "232",
  sha256 ? lib.fakeSha256, # <-- REPLACE with the real hash before building
}:

stdenv.mkDerivation {
  pname = "paper-server";
  version = "${mcVersion}-${build}";

  src = fetchurl {
    url = "https://api.papermc.io/v2/projects/paper/versions/${mcVersion}/builds/${build}/downloads/paper-${mcVersion}-${build}.jar";
    inherit sha256;
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/minecraft
    cp $src $out/lib/minecraft/paper.jar

    cat > $out/bin/minecraft-server <<EOF
    #!/bin/sh
    exec ${jdk25_headless}/bin/java "\$@" -jar $out/lib/minecraft/paper.jar nogui
    EOF
    chmod +x $out/bin/minecraft-server

    runHook postInstall
  '';

  meta = with lib; {
    description = "PaperMC Minecraft server, pinned to a specific build";
    homepage = "https://papermc.io";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "minecraft-server";
  };
}
