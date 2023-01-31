final: prev: {
  julia_pod = final.callPackage ./. {
    devspace = final.callPackage ./devspace-v5.nix {};
  };
}