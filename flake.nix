{
  description = "alass";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
        # Always succeeds so that the log is cached; `checks.test` decides pass/fail.
        test-report = alass.overrideAttrs {
          pname = "alass-test-report";
          buildPhase = ''
            runHook preBuild
            set +e
            cargo test --release --offline --workspace 2>&1 | tee test.log
            echo "''${PIPESTATUS[0]}" > status
            set -e
            runHook postBuild
          '';
          doCheck = false;
          installPhase = ''
            mkdir -p "$out"
            cp test.log status "$out/"
          '';
          dontFixup = true;
        };
      in
      {
        checks.test = runCommand "alass-test" { } ''
          if [ "$(cat ${test-report}/status)" != 0 ]; then
            cat ${test-report}/test.log >&2
            exit 1
          fi
          touch "$out"
        '';
        devShells.default = mkShell {
          buildInputs = [
            cargo
            just
            rustfmt
          ];
        };
        packages = {
          inherit alass test-report;
          default = alass;
        };
      }
    );
}
