final: prev:
{
  rubberband-shared = prev.rubberband.overrideAttrs (old: {
    # options taken from this fix https://github.com/flathub/org.kde.kdenlive/pull/68/files
    # ( interpretation of the respective json attribute "config-opts" is taken from https://docs.flatpak.org/en/latest/flatpak-builder-command-reference.html?highlight=config-opts )
    configureFlags = (old.configureFlags or []) ++ [
      "--disable-program"
      "--enable-shared"
      "--disable-static"
      "--without-ladspa"
      "--with-vamp"
      "--without-jni"
    ];
  });

  # ffmpeg can use rubberband for pitch compensation (works)
  ffmpeg-full = prev.ffmpeg-full.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [
      final.rubberband-shared
    ];
    configureFlags = (old.configureFlags or []) ++ [
      "--enable-librubberband"
    ];
  });

  # kdenlive can use rubberband for pitch compensation (does not work yet)
  kdenlive-pitch-compensation-still-not-working = (prev.kdenlive.override (old: {
      ffmpeg-full = final.ffmpeg-full;
    })
  ).overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [
      final.makeWrapper
      final.vamp-plugin-sdk
      final.rubberband-shared
    ];
    preBuild = (old.preBuild or "") + ''
      export PATH=${final.vamp-plugin-sdk}/bin:${final.rubberband-shared}/bin:$PATH
      export LD_LIBRARY_PATH=${final.vamp-plugin-sdk}/lib:${final.rubberband-shared}/lib:$LD_LIBRARY_PATH
      export XDG_DATA_DIRS=${final.rubberband-shared}/share:$XDG_DATA_DIRS
    '';
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/kdenlive \
        --prefix PATH : ${final.rubberband-shared}/bin \
        --prefix PATH : ${final.vamp-plugin-sdk}/bin \
        --prefix LD_LIBRARY_PATH : ${final.rubberband-shared}/lib \
        --prefix LD_LIBRARY_PATH : ${final.vamp-plugin-sdk}/lib \
        --prefix XDG_DATA_DIRS : ${final.rubberband-shared}/share
    '';
  });
}