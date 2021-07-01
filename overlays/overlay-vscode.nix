final: prev:
with final.lib;
with {
  my-vscode-extensions =
    with final.vscode-extensions; [
      # bbenoist.Nix
      # jnoortheen.nix-ide
      # scalameta.metals
      # scala-lang.scala
      # ms-python.python
      # ms-azuretools.vscode-docker
      # ms-vscode-remote.remote-ssh
    ] ++
    final.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "nix-env-selector";
        publisher = "arrterian";
        version = "1.0.7";
        sha256 = "0mralimyzhyp4x9q98x3ck64ifbjqdp8cxcami7clvdvkmf8hxhf";
      }
      {
        name = "language-julia";
        publisher = "julialang";
        version = "1.1.38";
        sha256 = "01x6ncnilblxgaqxi77ix6sqfc5y2ndyg9cix9as4sv38sfxdlkz";
      }
      {
        name = "git-graph";
        publisher = "mhutchie";
        version = "1.30.0";
        sha256 = "000zhgzijf3h6abhv4p3cz99ykj6489wfn81j0s691prr8q9lxxh";
      }
      {
        name = "jupyter";
        publisher = "ms-toolsai";
        version = "2021.6.795492900";
        sha256 = "1gxlpdlb4yfmzqsnf2alyc4rysgvsnn6jx5zm2nhhg0x2wrqmznw";
      }
      {
        name = "Nix";
        publisher = "bbenoist";
        version = "1.0.1";
        sha256 = "0zd0n9f5z1f0ckzfjr38xw2zzmcxg1gjrava7yahg5cvdcw6l35b";
      }
      {
        name = "nix-ide";
        publisher = "jnoortheen";
        version = "0.1.10";
        sha256 = "0c9x3br92rpsmc7d0i3c8rnvhyvwz7hvrrfd3sds9p168lz87gli";
      }
      {
        name = "latex-workshop";
        publisher = "james-yu";
        version = "8.17.0";
        sha256 = "04gwxx9hh66b605x72m12gmzp8f6fj594d9v9vq0c0wfv0l2bzbl";
      }
    ];
};
{
  vscode = pipe prev.vscode [
    (x: x.override {
      isInsiders = true;
    })
    (x: x.overrideAttrs (old: {
      # fixes for vscode-insiders
      # taken from https://discourse.nixos.org/t/how-to-install-latest-vscode-insiders/7895
      src = (builtins.fetchTarball {
        url = "https://update.code.visualstudio.com/latest/linux-x64/insider";
        sha256 = "0xcvwr71l07ryzlhhw943xlzc3yn2x0xiq0dzdlpcyyz9fs80hya";
      });
      version = "latest";
      buildInputs = old.buildInputs ++ [ final.xorg.libxshmfence ];
       
      # sudo-prompt has hardcoded binary paths on Linux and we patch them here
      # combining information from https://github.com/NixOS/nixpkgs/blob/fc553c0bc5411478e2448a707f74369ae9351e96/pkgs/tools/misc/etcher/default.nix#L49y
      # and https://github.com/NixOS/nixpkgs/issues/76526#issuecomment-569131432
      # and https://www.codepicky.com/hacking-electron-restyle-skype/
      patchPhase = (old.patchPhase or "") + ''
        # PATCHING RUN AS SUDO
        # --------------------
        # where to find the node.js librar .asar was described here https://github.com/NixOS/nixpkgs/issues/76526#issuecomment-569131432
        packed="resources/app/node_modules.asar"

        # we unpack directly into the same name without .asar ending,
        # which is adapted from hacking-skype-tutorial https://www.codepicky.com/hacking-electron-restyle-skype/
        unpacked="resources/app/node_modules"
        
        ${final.nodePackages.asar}/bin/asar extract "$packed" "$unpacked"

        # we change paths to pkexec and bash
        # as described here https://github.com/NixOS/nixpkgs/blob/fc553c0bc5411478e2448a707f74369ae9351e96/pkgs/tools/misc/etcher/default.nix#L49y
        sed -i "
          s|/usr/bin/pkexec|/run/wrappers/bin/pkexec|
          s|/bin/bash|${final.bash}/bin/bash|
        " "$unpacked/sudo-prompt/index.js"

        # delete original .asar file, as the new unpacked is now replacing it
        rm -rf "$packed"

        # PATCHING GLOBAL SEARCH
        # ----------------------
        chmod +x resources/app/node_modules/vscode-ripgrep/bin/rg
        '';
    }))
  ];
  vscode-with-extensions = pipe prev.vscode-with-extensions [
    (x: x.override {
      vscode = final.vscode;
      vscodeExtensions = my-vscode-extensions;
    })
  ];
}
