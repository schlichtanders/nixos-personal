with {
  tiddlydesktop = { pkgs, lib, stdenv, fetchFromGitHub, bash, nodejs, nodePackages, makeWrapper, makeDesktopItem, nwjs-sdk, gsettings-desktop-schemas, gtk3 }:
    stdenv.mkDerivation rec {
      pname = "tiddlydesktop";
      # 13 is latest version with nwjs-version <= nixos-nwjs-version (0.33.4)
      # we haven't been able to build our own newer version of nwjs, hence falling back to older version
      version = "0.0.15-prerelease.1";
      src = fetchFromGitHub {
        owner = "Jermolene";
        repo = "TiddlyDesktop";
        rev = "v" + version;
        sha256 = "1jqq0c5glkvdkjrgh5qxp0ski299igpy59ylg2wbgcq3vqcplr57";
      };

      # version = "0.0.14";
      # src = fetchFromGitHub {
      #   owner = "Jermolene";
      #   repo = "TiddlyDesktop";
      #   rev = "v" + version;
      #   sha256 = "122wq2sbbaw0jwk87jzxw752xwj2b6hc85235l8zfzd699i6kqb9";
      # };

      # version = "0.0.13";
      # src = fetchFromGitHub {
      #   owner = "Jermolene";
      #   repo = "TiddlyDesktop";
      #   rev = "v" + version;
      #   sha256 = "1ngyf1pdp4s75l6dx98sj6d7my322zykx315acaf3w6i6gk7cp7q";
      # };

      nativeBuildInputs = [ nodejs makeWrapper ];
      buildInputs = [ bash nwjs-sdk gsettings-desktop-schemas gtk3];

      buildPhase = ''
        # no need to cleanup, because we are using nix
        # no need to get correct version of TiddlyWiki5 manually, using the nixpkgs version instead

        # Copy TiddlyWiki core files into the source directory
        cp -RH ${nodePackages.tiddlywiki}/lib/node_modules/tiddlywiki ./source/tiddlywiki
        # fix rights
        chmod u+w -R ./source/tiddlywiki
        
        # Copy TiddlyDesktop plugin into the source directory
        cp -RH ./plugins/tiddlydesktop ./source/tiddlywiki/plugins/tiddlywiki

        # Copy TiddlyDesktop version number from package.json to the plugin.info of the plugin and the tiddler $:/plugins/tiddlywiki/tiddlydesktop/version
        node ./propagate-version.js
        
        # Linux 64-bit App
        mkdir -p ./output/linux64/TiddlyDesktop-linux64-v${version}
        cp -RH ./source/* ./output/linux64/TiddlyDesktop-linux64-v${version}
      '';

      desktopItem = makeDesktopItem {
        name = "TiddlyDesktop";
        desktopName = "Tiddly Desktop";
        exec = "tiddlydesktop";
        icon = "tiddlydesktop";
        comment = "TiddlyDesktop";
        genericName = "Desktop application to manage tiddly wikis.";
        categories = "GNOME;GTK;Utility;";
      };

      installPhase = ''
        # Install Tiddly Desktop
        mkdir -p $out/build
        mv ./output/linux64/* $out/build/

        # Create Launcher
        mkdir -p $out/bin
        makeWrapper "${nwjs-sdk}/bin/nw" "$out/bin/tiddlydesktop" \
          --add-flags "$out/build/TiddlyDesktop-linux64-v${version}" \
          --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
          --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}"  # it seems we only need gtk3, however the other one where directly mentioned in the error message

        # Create Desktop Item
        mkdir -p "$out/share/applications"
        ln -s "${desktopItem}"/share/applications/* "$out/share/applications/"
        mkdir -p "$out/share/icons/hicolor/128x128/apps"  # the long folder path is crucial, just using $out/share/icons does not work
        ln -s "$out/build/TiddlyDesktop-linux64-v${version}/images/app-icon.png" "$out/share/icons/hicolor/128x128/apps/tiddlydesktop.png"  
      '';

      meta = with lib; {
        description = "A custom desktop browser for TiddlyWiki 5 and TiddlyWiki Classic, based on nw.js";
        homepage = "https://github.com/Jermolene/TiddlyDesktop";
        platforms = [ "x86_64-linux" ];
        license = licenses.bsd0;
      };
    };
};
final: prev: {
  tiddlydesktop = final.callPackage tiddlydesktop { nwjs-sdk = final.nwjs_0_51-sdk; };
}