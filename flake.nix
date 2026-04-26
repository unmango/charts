{
  description = "A Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    mynix = {
      url = "github:UnstoppableMango/nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
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
              mynix.overlays.default
            ];
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
