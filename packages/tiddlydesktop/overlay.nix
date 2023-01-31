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
        categories = ["GNOME" "GTK" "Utility"];
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

nwjs_0_51 = 
  { stdenv, lib, fetchurl, buildEnv, makeWrapper

  , xorg, alsaLib, dbus, glib, gtk3, atk, pango, freetype, fontconfig
  , gdk-pixbuf, cairo, nss, nspr, gconf, expat, systemd, libcap
  , libnotify
  , ffmpeg, libxcb, cups
  , sqlite, udev
  , libuuid
  , libdrm
  , libxkbcommon
  , mesa  # required for libgbm
  , at-spi2-core  # required for libatspi
  , sdk ? false
  }:
  let
    bits = "x64";

    nwEnv = buildEnv {
      name = "nwjs-env";
      paths = [
        xorg.libX11 xorg.libXrender glib /*gtk2*/ gtk3 atk pango cairo gdk-pixbuf
        freetype fontconfig xorg.libXcomposite alsaLib xorg.libXdamage
        xorg.libXext xorg.libXfixes nss nspr gconf expat dbus
        xorg.libXtst xorg.libXi xorg.libXcursor xorg.libXrandr
        xorg.libXScrnSaver cups
        libcap libnotify
        # libnw-specific (not chromium dependencies)
        ffmpeg libxcb
        # chromium runtime deps (dlopen’d)
        sqlite udev
        libuuid
        # extra dependencies needed
        libdrm
        libxkbcommon
        mesa  # required for libgbm
        at-spi2-core  # required for libatspi
      ];

      extraOutputsToInstall = [ "lib" "out" ];
    };

  in stdenv.mkDerivation rec {
    pname = "nwjs";
    version = "0.51.1";

    src = if sdk then fetchurl {
      url = "https://dl.nwjs.io/v${version}/nwjs-sdk-v${version}-linux-${bits}.tar.gz";
      sha256 = "0k4bg6v7sn6r6ddwvlgxbszmk9l6pcn8xhkl4qp05wg2nzjvkrw3";
    } else fetchurl {
      url = "https://dl.nwjs.io/v${version}/nwjs-v${version}-linux-${bits}.tar.gz";
      sha256 = "0pcazf7wfh5ky8b9nfy1xm2nmmfk9hgzr12xjcpx0834rml3kd7g";
    };
    # version = "0.45.5";

    # src = if sdk then fetchurl {
    #   url = "https://dl.nwjs.io/v${version}/nwjs-sdk-v${version}-linux-${bits}.tar.gz";
    #   sha256 = "02i83wv1g379lkxlh7y0nz665g26wmpb1syqhk5dkmdxgmcx9544";
    # } else fetchurl {
    #   url = "https://dl.nwjs.io/v${version}/nwjs-v${version}-linux-${bits}.tar.gz";
    #   sha256 = "1b5n31aix7ca7as0zvs2y79k9x4rd98g6lhpmr9mqfsmy9iwzmds";
    # };

    phases = [ "unpackPhase" "installPhase" ];

    # we have runtime deps like sqlite3 that should remain
    dontPatchELF = true;

    installPhase =
      let ccPath = lib.makeLibraryPath [ stdenv.cc.cc ];
      in ''
        mkdir -p $out/share/nwjs
        cp -R * $out/share/nwjs
        find $out/share/nwjs
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/share/nwjs/nw
        ln -s ${lib.getLib systemd}/lib/libudev.so $out/share/nwjs/libudev.so.0
        libpath="$out/share/nwjs/lib/"
        for f in "$libpath"/*.so; do
          patchelf --set-rpath "${nwEnv}/lib:${ccPath}:$libpath" "$f"
        done
        patchelf --set-rpath "${nwEnv}/lib:${nwEnv}/lib64:${ccPath}:$libpath" $out/share/nwjs/nw
        # check, whether all RPATHs are correct (all dependencies found)
        checkfile=$(mktemp)
        for f in "$libpath"/*.so "$out/share/nwjs/nw"; do
          (echo "$f:";
            ldd "$f"  ) > "$checkfile"
        done
        if <"$checkfile" grep -e "not found"; then
          cat "$checkfile"
          exit 1
        fi
        mkdir -p $out/bin
        ln -s $out/share/nwjs/nw $out/bin
    '';

    nativeBuildInputs = [ makeWrapper ];

    meta = with lib; {
      description = "An app runtime based on Chromium and node.js";
      homepage = "https://nwjs.io/";
      platforms = ["i686-linux" "x86_64-linux"];
      maintainers = [ ];
      license = licenses.bsd3;
    };
  };
};
final: prev: {
  tiddlydesktop = final.callPackage tiddlydesktop {
    nwjs-sdk = final.nwjs_0_51-sdk;
  };
  nwjs_0_51 = final.callPackage nwjs_0_51 {
    gconf = final.gnome2.GConf;
  };
  nwjs_0_51-sdk = final.callPackage nwjs_0_51 {
    gconf = final.gnome2.GConf;
    sdk = true;
  };
  
}