{
  autoPatchelfHook,
  jdk,
  requireFile,
  stdenvNoCC,
  unzip
}:
let
  version = "2.18.0";
in
stdenvNoCC.mkDerivation {
  pname = "stm32cubeprog";
  inherit version;

  src = requireFile {
    name = "en.stm32cubeprg-lin-v${builtins.replaceStrings [ "." ] [ "-" ] version }.zip";
    # name = "en.stm32cubeprg-lin-v2-18-0.zip";
    url = "https://www.st.com/en/development-tools/stm32cubeprog.html#get-software";
    hash = "sha256-OyMCTdqzgDouzILFcf6ujn07KSpdxnQp+IEveiA6TIw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    jdk
    unzip
  ];


  buildCommand = ''
    unzip $src
    ls -Alh --color=auto jre/bin
    ./SetupSTM32CubeProgrammer-${version}.linux
  '';
}
