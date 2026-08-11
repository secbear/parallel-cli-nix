{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  zlib,
  bash,
}:

let
  version = "0.8.2";
  repo = "parallel-web/parallel-web-tools";

  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  hashes = {
    "linux-x64" = "sha256:11af85009247ad26b42f81e70bf443a55b5f33c269dbae7a7e6a3ac367434acb";
    "linux-arm64" = "sha256:d4e417f2ba8eaf1154a3082dfc51893f08f83d03b4c42af9388dbf5b3f13c5c4";
    "darwin-x64" = "sha256:6c6d513088f7dfe0cbbe372dfa01800c177189f183bc683b86e02d8e8df4a086";
    "darwin-arm64" = "sha256:223e7b434b5912bbad90cbba17fb46e7a50ef6e290db53d4a778457310e7b32f";
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  isLinux = stdenv.hostPlatform.isLinux;
in

stdenv.mkDerivation {
  pname = "parallel-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/v${version}/parallel-cli-${platform}.zip";
    hash = hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = [ unzip ]
    ++ lib.optionals isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals isLinux [
    stdenv.cc.cc.lib
    zlib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/parallel-cli $out/bin

    cp parallel-cli/parallel-cli $out/lib/parallel-cli/parallel-cli
    chmod +x $out/lib/parallel-cli/parallel-cli
    cp -r parallel-cli/_internal $out/lib/parallel-cli/_internal

    cat > $out/bin/parallel-cli <<WRAPPER
    #!${bash}/bin/bash
    exec $out/lib/parallel-cli/parallel-cli "\$@"
    WRAPPER
    chmod +x $out/bin/parallel-cli

    runHook postInstall
  '';

  # On macOS the binary links to system dylibs (libSystem, libz) which is fine.
  # On Linux autoPatchelfHook handles the dynamic linker and rpath.
  dontFixup = !isLinux;

  meta = {
    description = "AI-powered web search, extraction, and research CLI from parallel.ai";
    homepage = "https://parallel.ai";
    changelog = "https://github.com/${repo}/releases/tag/v${version}";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platformMap;
    mainProgram = "parallel-cli";
  };
}
