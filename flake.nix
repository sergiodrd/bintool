{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    cargo2nix = {
      url = "github:cargo2nix/cargo2nix/release-0.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.follows = "cargo2nix/flake-utils";
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
          bintool = (rustPkgs.workspace.bintool {});
          default = packages.bintool;

          container = pkgs.dockerTools.buildImage {
            name = "bintool";
            tag = packages.bintool.version;
            created = "now";
            copyToRoot = packages.bintool;
            config.Cmd = [ "${packages.bintool}/bin/bintool" ];
          };
        };
      }
    );
}
