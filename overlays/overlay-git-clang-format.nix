with {
    git-clang-format =
        { pkgs, lib, stdenv, fetchurl, python, clang-tools, makeWrapper }:
        stdenv.mkDerivation rec {
            pname = "git-clang-format";
            version = "13.0.0";

            # we cannot use the standard `src` attribute, as this would get unpacked
            # any non-standard argument as here `executable` is just passed internally
            # and thanks to `rec` we can also access it with nix interpolation syntax
            executable = fetchurl {
                url = "https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-${version}/clang/tools/clang-format/${pname}";
                sha256 = "1wxa2jmw123lbk9q786qzjyfkr2pkvvcp0qm5ipy5qc6i9dndj0c";
            };

            nativeBuildInputs = [ makeWrapper ];
            buildInputs = [ python ];

            # Remove all phases except installPhase
            phases = [ "installPhase" ];

            installPhase = ''
                runHook preInstall
                
                mkdir -p $out/bin
                cp ${executable} $out/bin/${pname}
                chmod +x $out/bin/${pname}
                
                wrapProgram $out/bin/${pname} \
                  --suffix-each PATH : "${clang-tools}/bin ${python}/bin"
                
                runHook postInstall
            '';

            meta = clang-tools.meta // {
                description = "clang-format git integration";
            };
        };
};
final: prev: {
  git-clang-format = final.callPackage git-clang-format {};
}