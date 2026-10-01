default:
    @just --list

alias b := build
alias c := check
alias u := update

# Build the alass package
build:
    nix build

# Run tests and other checks
check: test

_nix-system:
    @nix eval --impure --raw --expr 'builtins.currentSystem'

# Run the test suite and print its log
test:
    #!/usr/bin/env bash
    set -euo pipefail
    out=$(nix build --no-link --print-out-paths .#test-report)
    cat "$out/test.log"
    nix build --no-link ".#checks.$(just _nix-system).test"

# Update Cargo.lock and flake.lock
update:
    nix develop -c cargo update
    nix flake update
