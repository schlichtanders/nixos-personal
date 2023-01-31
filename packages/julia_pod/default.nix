{ pkgs, lib, stdenv, fetchFromGitHub, makeWrapper, devspace, jq, openssl, envsubst }:
stdenv.mkDerivation rec {
  pname = "julia_pod";
  version = "2023-01-30";

  src = fetchFromGitHub {
    owner = "beacon-biosignals";
    repo = "julia_pod";
    rev = "9278758c79f6f10992c600cb1429ad93f8d908f4";
    sha256 = "B1vnr6oBrMvZEub6ElcxNSQaqqRu1J95zQqslcM0so0=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # inputs which are added to the PATH
  runtimeInputs = [
    devspace  # caution, more recent nixos come with devspace version 6.x, which is incompatible with julia_pod so far
    jq
    openssl
    envsubst
  ];

  installPhase = ''
      runHook preInstall

      mkdir $out
      mv add_me_to_your_PATH $out/bin
      chmod +x $out/bin/${pname}

      # we need to empty this file, it only contains example environment variables
      # which should be changed according to instructions
      # we recommend setting these environment variables in your shell setup instead
      rm $out/bin/accounts.sh
      touch $out/bin/accounts.sh

      wrapProgram $out/bin/${pname} \
        --set DOCKER_BUILDKIT 1 \
        --set DOCKER_CLI_EXPERIMENTAL enabled \
        --prefix PATH : ${lib.makeBinPath runtimeInputs}

      runHook postInstall
  '';

  meta = with lib; {
    description = "k8s native julia development";
    homepage = "https://github.com/beacon-biosignals/julia_pod/";
    license = licenses.mit;
    maintainers = [ "Stephan Sahm <stephan.sahm@jolin.io>" ];
  };
}