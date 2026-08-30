{
  description = "Professional, modular Paper Minecraft server for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Secrets management (RCON password, backup destination creds, etc.)
    # never store secrets as plaintext strings in Nix config - they land
    # world-readable in /nix/store otherwise.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # The reusable module - import this into any NixOS host config.
      nixosModules.minecraftPro = import ./modules/minecraft;
      nixosModules.default = self.nixosModules.minecraftPro;

      # Standalone packages you can build/inspect on their own,
      # e.g. `nix build .#paperServer`.
      packages.${system} = {
        paperServer = pkgs.callPackage ./pkgs/paper.nix { };
      };

      # Optional full host example - useful for a VM smoke test:
      # `nixos-rebuild build-vm --flake .#exampleHost`
      nixosConfigurations.exampleHost = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit agenix; };
        modules = [
          agenix.nixosModules.default
          self.nixosModules.minecraftPro
          ./example/configuration.nix
        ];
      };

      # `nix develop` gives you a JDK + Maven shell for building plugin jars.
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.jdk25
          pkgs.maven
          pkgs.mcrcon
        ];
      };
    };
}
