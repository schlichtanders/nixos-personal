final: prev:
{
  pdfarranger = prev.pdfarranger.overrideAttrs (old: {
    # PDFarranger needs this LC_ALL in order to work, however it is generally recommended to leave it unset. Hence we should overwrite pdfarranger with wrapprogram
    postInstall = ''
      wrapProgram $out/bin/pdfarranger --set LC_ALL en_US.UTF-8
    '';
  });
}