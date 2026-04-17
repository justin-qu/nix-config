# M4 MacBook Pro

[nix-darwin](https://github.com/nix-darwin/nix-darwin) configuration for Apple Silicon MacBook Pro using [Determinate Nix](https://determinate.systems).

## First-time Setup

1. Install Determinate Nix: https://determinate.systems/nix/
2. Apply the configuration:

```bash
nix develop --command apply-nix-darwin-configuration
```

## Applying Changes

```bash
nix develop --command apply-nix-darwin-configuration
```

Or directly:

```bash
sudo darwin-rebuild switch --flake .#aarch64-darwin
```
