{
  lib
, stdenv
, fetchurl
, jre
, unzip
, makeWrapper
}:
stdenv.mkDerivation rec {
  pname = "structurizr-cli";
  version = "2024.03.03";

  src = fetchurl {
    url = "https://github.com/structurizr/cli/releases/download/v${version}/${pname}.zip";
    hash = "sha256-4M/7iLW5mLu+rkKKRjzwARVOgmaM6MYbn4fMsnQ7sfc=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  installPhase = ''
    runHook preInstall

    pwd
    mkdir -p $out/bin

    makeWrapper ${jre}/bin/java $out/bin/${pname} \
        --add-flags "-Djdk.util.jar.enableMultiRelease=false" \
        --add-flags "-jar $src"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://docs.structurizr.com/cli";
    description = "The Structurizr CLI is a command line utility designed to be used in conjunction with the Structurizr DSL";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ jpteb ];
    mainProgram = "structurizr-cli";
  };
}
