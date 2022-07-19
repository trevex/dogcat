{
  description = "dogcat";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      overlays = [
        (final: prev: {
          go-reflex = prev.callPackage
            ({ buildGoModule, fetchFromGitHub }: buildGoModule rec {
              pname = "reflex";
              version = "0.3.1";

              src = fetchFromGitHub {
                owner = "cespare";
                repo = pname;
                rev = "v${version}";
                sha256 = "sha256-/2qVm2xpSFVspA16rkiIw/qckxzXQp/1EGOl0f9KljY=";
              };
              vendorSha256 = "sha256-JCtVYDHbhH2i7tGNK1jvgHCjU6gMMkNhQ2ZnlTeqtmA=";
              doCheck = false;
            })
            { };
        })
      ];
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      rec {
        devShell = pkgs.mkShell rec {
          name = "dogcat";

          buildInputs = with pkgs; [
            go
            go-reflex
            golangci-lint
            delve
            yarn
            nodejs-16_x
            gnumake
            findutils
            tmux
          ];
        };
      }
    );
}
