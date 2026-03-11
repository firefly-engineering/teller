# Teller

Versioned toolchain registry library for the [Turnkey](https://github.com/firefly-engineering/turnkey) project.

Teller provides the mechanics to define, compose, and resolve versioned toolchain registries as Nix overlays. It ships a default registry of common toolchains and a set of library functions that Turnkey (and custom registries) use to manage toolchain versions.

## Features

- **Version pinning** — projects request exact toolchain versions (e.g. Go 1.22, Python 3.12)
- **Composable registries** — multiple registries stack as Nix overlays with automatic two-level merging (toolchain + version level)
- **Meta-packages** — bundle related tools (e.g. rustc + cargo + clippy) into a single entry
- **Deprecation & EOL warnings** — extended version entries can carry metadata that emits warnings during evaluation
- **Default registry** — ships common toolchains from nixpkgs out of the box (Go, Rust, Python, Node.js, C/C++, Solidity, and more)

## Usage

### As a registry input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    teller.url = "github:firefly-engineering/teller";
  };

  outputs = { nixpkgs, teller, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ teller.overlays.default ];
      };
    in {
      # pkgs.turnkeyRegistry now contains the default toolchain registry
    };
}
```

### Resolving toolchains

```nix
# Resolve a single tool (explicit version)
go = teller.lib.resolveTool pkgs.turnkeyRegistry "go" { version = "1.22"; };

# Resolve a single tool (registry default)
rust = teller.lib.resolveTool pkgs.turnkeyRegistry "rust" {};

# Resolve all toolchains from a toolchain.toml
packages = teller.lib.resolveToolchains pkgs.turnkeyRegistry
  (builtins.fromTOML (builtins.readFile ./toolchain.toml));
```

### Writing a custom registry

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    teller.url = "github:firefly-engineering/teller";
  };

  outputs = { teller, ... }: {
    overlays.default = teller.lib.mkRegistryOverlay (final: prev: {
      go = {
        versions = {
          "1.22" = final.go_1_22;
          "1.23" = final.go_1_23;
        };
        default = "1.23";
      };
    });
  };
}
```

Custom registries compose with the default registry — versions merge additively and later overlays can override defaults.

## Library

Teller exports the following functions via `teller.lib`:

| Function | Description |
|---|---|
| `mkRegistryOverlay` | Create a Nix overlay that merges toolchain versions into `pkgs.turnkeyRegistry` |
| `mkMetaPackage` | Bundle multiple components into a single derivation with all binaries in `$out/bin` |
| `resolveTool` | Look up a single toolchain version from the registry |
| `resolveToolchains` | Resolve all toolchains from a parsed `toolchain.toml` declaration |

## Default registry

The built-in registry (`registry/default.nix`) provides single-version entries for common toolchains sourced from nixpkgs:

Go, Rust (rustc, cargo, clippy, rustfmt, rust-analyzer, cargo-edit, reindeer), Python (python3, uv, ruff, pytest), C/C++ (cc, clang, lld), Node.js, TypeScript, Biome, Solidity (solc, foundry), Buck2, Nix, jq, mdbook.

## Documentation

See [`docs/specs/versioned-registry.md`](docs/specs/versioned-registry.md) for the full specification, including composition semantics, deprecation metadata, and migration guidance.

## License

[MIT](LICENSE)
