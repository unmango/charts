{
  description = "A Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    mynix = {
      url = "github:UnstoppableMango/nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        gomod2nix.inputs.flake-utils.follows = "flake-utils";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    nixhelm = {
      url = "github:nix-community/nixhelm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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
        { inputs', pkgs, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = with inputs; [
              mynix.overlays.default
            ];
          };

          apps = {
            inherit (inputs'.nixhelm.apps) helmupdater;
          };

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

            HELM = "${pkgs.kubernetes-helm}/bin/helm";
            KIND = "${pkgs.kind}/bin/kind";
            CR = "${pkgs.chart-releaser}/bin/cr";
            CT = "${pkgs.chart-testing}/bin/ct";
          };

          treefmt.programs = {
            nixfmt.enable = true;
            gofmt.enable = true;
          };
        };
    };
}
