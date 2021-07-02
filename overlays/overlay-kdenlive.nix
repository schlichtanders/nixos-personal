final: prev:
{
  rubberband_kdenlive = prev.rubberband.overrideAttrs (old: {
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

  # also used by kdenlive
  ffmpeg-full = prev.ffmpeg-full.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [
      final.rubberband_kdenlive
    ];
    configureFlags = (old.configureFlags or []) ++ [
      "--enable-librubberband"
    ];
  });
  
  kdenlive = (prev.kdenlive.override (old: {
      ffmpeg-full = final.ffmpeg-full;
    })
  ).overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [
      final.makeWrapper
      final.vamp-plugin-sdk
      final.rubberband_kdenlive
    ];
    preBuild = (old.preBuild or "") + ''
      export PATH=${final.vamp-plugin-sdk}/bin:${final.rubberband_kdenlive}/bin:$PATH
      export LD_LIBRARY_PATH=${final.vamp-plugin-sdk}/lib:${final.rubberband_kdenlive}/lib:$LD_LIBRARY_PATH
      export XDG_DATA_DIRS=${final.rubberband_kdenlive}/share:$XDG_DATA_DIRS
    '';
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/kdenlive \
        --prefix PATH : ${final.rubberband_kdenlive}/bin \
        --prefix PATH : ${final.vamp-plugin-sdk}/bin \
        --prefix LD_LIBRARY_PATH : ${final.rubberband_kdenlive}/lib \
        --prefix LD_LIBRARY_PATH : ${final.vamp-plugin-sdk}/lib \
        --prefix XDG_DATA_DIRS : ${final.rubberband_kdenlive}/share
    '';
  });
}