Put your agenix-encrypted secrets here, e.g. `rcon-password.age`.

Create one with:
    nix run github:ryantm/agenix -- -e secrets/rcon-password.age

This file is intentionally the only thing in this directory - the actual
.age files are secrets and shouldn't ship in a template repo.
