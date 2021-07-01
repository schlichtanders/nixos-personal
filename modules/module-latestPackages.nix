{ config, pkgs, lib, ... }:
with {
    overlay-latestPackages = final: prev:
        let latestPkgs = import (fetchTarball https://github.com/nixos/nixpkgs-channels/archive/nixpkgs-unstable.tar.gz) {
            config.allowUnfree = true;
        };
        in lib.genAttrs config.nixpkgs.latestPackages (pkg: latestPkgs."${pkg}");
};
{
    options = {
        nixpkgs.latestPackages = lib.mkOption { default = []; };
    };

    config = {
        ###
        # DIRTY HACK
        # This will fetch latest packages on each rebuild, whatever channel you are at
        nixpkgs.overlays = [ overlay-latestPackages ];
        # END DIRTY HACK
        ###
    };
}
