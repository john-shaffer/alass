{
  description = "alass";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      with pkgs;
      let
        alass = rustPlatform.buildRustPackage rec {
          pname = "alass";
          version = "2.0.0";

          src = self;
          cargoLock = {
            lockFile = src + "/Cargo.lock";
          };

          nativeBuildInputs = [ makeWrapper ];

          doCheckPhase = false;

          postInstall = ''
            wrapProgram "$out/bin/alass-cli" --prefix PATH : "${lib.makeBinPath [ ffmpeg ]}"
          '';

          meta = {
            description = "Automatic Language-Agnostic Subtitles Synchronization";
            homepage = "https://github.com/john-shaffer/alass";
            license = lib.licenses.gpl3Plus;
            mainProgram = "alass-cli";
          };
        };
      in
      {
        devShells.default = mkShell {
          buildInputs = [
            cargo
            rustfmt
          ];
        };
        packages = {
          inherit alass;
          default = alass;
        };
      }
    );
}
