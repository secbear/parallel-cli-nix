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
  version = "0.6.1";
  repo = "parallel-web/parallel-web-tools";

  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  hashes = {
    "linux-x64" = "sha256:b9873576427bb14011f2489f28cf0c878db9279e76159456c51d54f110a1acae";
    "linux-arm64" = "sha256:0aef6bd3b58019b9f002ad8c1fd6652b7dc32996a944000a71670667eb1f3526";
    "darwin-x64" = "sha256:4d29cc5e7f8a0a80c852a50f6bbce7f8356e21bff01777e9fd4ef3770bdf9ed8";
    "darwin-arm64" = "sha256:53b6939481dcb9abbaa4985c660298a75bad0217f285f4323c57a5e8ad24fe5a";
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
