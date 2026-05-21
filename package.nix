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
  version = "0.5.0";
  repo = "parallel-web/parallel-web-tools";

  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  hashes = {
    "linux-x64" = "sha256:a9b1bc745e8be4043c2655354e75a35a6a9af594abf935a08b1dad87bd7cf0aa";
    "linux-arm64" = "sha256:1d80479aa2ab1104cd7e218f0fe8e800810fb51b430ef1eb408d78afbca4dfe6";
    "darwin-x64" = "sha256:6678d0cc2c3fa60cf5cac5c06fe3086a6f268dbb5212b73ba66f4ba30382eb66";
    "darwin-arm64" = "sha256:6151e374f070d855dbf1b2a066eec843b358b6a53728e5b68f89f4e9a08eb83c";
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
