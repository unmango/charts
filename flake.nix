{
  description = "A Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    mangopkgs = {
      url = "github:unmango/pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = with inputs; [
        treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = with inputs; [
              mangopkgs.overlays.default
            ];
          };

          # The generated half of charts/gha-runner-scale-set, which `make chart-gha-runner-scale-set` copies
          # into the worktree and CI checks for drift.
          packages.gha-runner-scale-set = pkgs.callPackage ./charts/gha-runner-scale-set/package.nix { };

          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              chart-releaser
              chart-testing
              direnv
              gnumake
              kubernetes-helm
              kind
              nixfmt
            ];
          };

          treefmt.programs = {
            actionlint.enable = true;
            gofmt.enable = true;
            mdformat.enable = true;
            nixfmt.enable = true;
          };
        };
    };
}
