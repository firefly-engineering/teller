{
  description = "Teller — versioned toolchain registry library for Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Library is system-independent (no pkgs closure)
      tellerLib = import ./lib {
        lib = nixpkgs.lib;
        currentTime = self.lastModified or 0;
      };
    in
    {
      # System-independent library exports
      lib = tellerLib;

      # Default registry as an overlay
      overlays.default = tellerLib.mkRegistryOverlay (
        final: prev: import ./registry { pkgs = final; }
      );
    };
}
