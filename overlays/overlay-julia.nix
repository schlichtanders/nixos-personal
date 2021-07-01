final: prev:
with rec {
  pkgs = final;
  julia_16 = pkgs.stdenv.mkDerivation {
    name = "julia_16";
    src = pkgs.fetchurl {
      url = "https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.1-linux-x86_64.tar.gz";
      sha256 = "01i5sm4vqb0y5qznql571zap19b42775drrcxnzsyhpaqgg8m23w";
    };
    installPhase = ''
      mkdir $out
      cp -R * $out/

      # Patch for https://github.com/JuliaInterop/RCall.jl/issues/339.

      echo "patching $out"
      cp -L ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 $out/lib/julia/
    '';
    dontStrip = true;
    ldLibraryPath = with pkgs; lib.makeLibraryPath [
      stdenv.cc.cc
      zlib
      glib
      xorg.libXi
      xorg.libxcb
      xorg.libXrender
      xorg.libX11
      xorg.libSM
      xorg.libICE
      xorg.libXext
      dbus
      fontconfig
      freetype
      libGL
    ];
  };
  targetPkgs = pkgs: with pkgs; [
    autoconf
    curl
    gnumake
    utillinux
    m4
    gperf
    unzip
    stdenv.cc
    clang
    binutils
    which
    gmp
    libxml2
    cmake

    fontconfig
    openssl
    which
    ncurses
    gtk2-x11
    atk
    gdk_pixbuf
    cairo
    xorg.libX11
    xorg.xorgproto
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXext
    xorg.libSM
    xorg.libICE
    xorg.libX11
    xorg.libXrandr
    xorg.libXdamage
    xorg.libXrender
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libxcb
    xorg.libXi
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libXt
    xorg.libXxf86vm
    xorg.libXinerama
    nspr
    pdf2svg

    # Nvidia note: may need to change cudnn to match cudatoolkit version
    # cudatoolkit_10_0
    # cudnn_cudatoolkit_10_0
    # linuxPackages.nvidia_x11

    julia_16

    # Arpack.jl
    arpack
    gfortran.cc
    (pkgs.runCommand "openblas64_" {} ''
    mkdir -p "$out"/lib/
    ln -s ${openblasCompat}/lib/libopenblas.so "$out"/lib/libopenblas64_.so.0
    '')

    # Cairo.jl
    cairo
    gettext
    pango.out
    glib.out
    # Gtk.jl
    gtk3
    gtk2
    fontconfig
    gdk_pixbuf
    # GR.jl # Runs even without Xrender and Xext, but cannot save files, so those are required
    qt4
    glfw
    freetype

    conda

    # misc
    xorg.libXxf86vm
    xorg.libSM
    xorg.libXtst
    libpng
    expat
    gnome2.GConf
    nss
  ];

  env_vars = ''
    export EXTRA_CCFLAGS="-I/usr/include"

    # Uncomment this to use a different path for Julia.
    # Note that multiple Julia versions can use the same depot path without problems.
    # export JULIA_DEPOT_PATH="~/.julia-1.6:$JULIA_DEPOT_PATH"
  '';
  extraOutputsToInstall = ["man" "dev"];
  multiPkgs = pkgs: with pkgs; [ zlib ];

  julia-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "julia"; # Name used to start this UserEnv
    multiPkgs = multiPkgs;
    runScript = "julia";
    extraOutputsToInstall = extraOutputsToInstall;
    profile = env_vars;
  };
};
{
  julia = julia-fhs;
}
