{
  inputs = {
    cargo2nix.url = "github:cargo2nix/cargo2nix/release-0.11.0";
    flake-utils.follows = "cargo2nix/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nixpkgs.follows = "cargo2nix/nixpkgs";
  };

  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ 
            rust-overlay.overlays.default
            cargo2nix.overlays.default
          ];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          rustVersion = "1.73.0";
          packageFun = import ./Cargo.nix;
        };

      in rec {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            flyctl
            rust-bin.stable.latest.default
          ];
        };

        packages = {
        };
      }
    );
}
