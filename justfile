default:
    @just --list

alias b := build
alias u := update

# Build the alass package
build:
    nix build

# Update Cargo.lock and flake.lock
update:
    nix develop -c cargo update
    nix flake update
