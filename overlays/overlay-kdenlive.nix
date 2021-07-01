final: prev:
{
  rubberband_kdenlive = prev.rubberband.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ final.makeWrapper ];
    # options taken from this fix https://github.com/flathub/org.kde.kdenlive/pull/68/files
    # ( interpretation of the respective json attribute "config-opts" is taken from https://docs.flatpak.org/en/latest/flatpak-builder-command-reference.html?highlight=config-opts )
    configureFlags = [
      "--disable-program"
      "--enable-shared"
      "--disable-static"
      "--without-ladspa"
      "--with-vamp"
      "--without-jni"
    ];
  });

  kdenlive = prev.kdenlive.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [final.vamp-plugin-sdk final.rubberband_kdenlive];
  });
}