with {
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
final: prev: let pkgs = final; in {
  nwjs_0_51 = pkgs.callPackage nwjs_0_51 {
    gconf = pkgs.gnome2.GConf;
  };
  nwjs_0_51-sdk = pkgs.callPackage nwjs_0_51 {
    gconf = pkgs.gnome2.GConf;
    sdk = true;
  };
}