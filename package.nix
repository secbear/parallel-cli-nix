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
  version = "0.4.0";
  repo = "parallel-web/parallel-web-tools";

  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  hashes = {
    "linux-x64" = "sha256:7973d7c9b418b5fa3b7c8e8160d6c8d1d7266890e74248bd9915136ea3d4b53d";
    "linux-arm64" = "sha256:e135bb428f096049446f49383488448a242cabbf015b817a7f555cbd386f72c8";
    "darwin-x64" = "sha256:d4545771ebf979024c1b7e8617aee109e9554cfa4e70b6198fa306081c0ce67f";
    "darwin-arm64" = "sha256:50059e648d8df0fb9ea229aaa993c929821b3deb2140ed1a2f7b950c449233b7";
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
