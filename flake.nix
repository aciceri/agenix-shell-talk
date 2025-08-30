{
  description = "Talk about agenix-shell for NixCon 2025";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = with inputs; [
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          treefmt.config = {
            projectRootFile = ".git/config";
            flakeFormatter = true;
            flakeCheck = true;
            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
            };
            settings.global.excludes = [
              ".envrc"
              "LICENSE"
            ];
          };

          pre-commit = {
            check.enable = false;
            settings.hooks = {
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
            };
          };
          packages = {
            agenix-shell-talk = pkgs.stdenv.mkDerivation (finalAttrs: {
              pname = "agenix-shell-talk";
              version = "1.0.0";

              src = lib.fileset.toSource {
                root = ./.;
                fileset = lib.fileset.difference (lib.fileset.fromSource ./.) (
                  lib.fileset.unions [
                    ./README.md
                    ./LICENSE
                    ./.github
                  ]
                );
              };

              nativeBuildInputs = with pkgs; [
                nodejs
                pnpm.configHook
              ];

              pnpmDeps = pkgs.pnpm.fetchDeps {
                inherit (finalAttrs) pname version src;
                fetcherVersion = 2;
                hash = "sha256-i3vEHiH69Zp/Dwq6EZ2GWnigyjWVVBD+71qQmeR9s6k=";
              };

              buildPhase = ''
                runHook preBuild
                pnpm build
                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall
                cp -r dist $out
                runHook postInstall
              '';

              meta = {
                description = "Presentation about agenix-shell for a 5-minute flash talk at NixCon 2025";
                license = lib.licenses.mit;
                maintainers = with lib.maintainers; [ aciceri ];
              };
            });
            default = config.packages.agenix-shell-talk;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              pnpm
              nodejs_20
            ];

            shellHook = ''
              ${config.pre-commit.installationScript}
              pnpm install
            '';
          };
        };
    };
}
