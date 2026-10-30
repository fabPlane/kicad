#!/usr/bin/env bash
# Homebrew build dependencies for the headless kicad-cli on macOS (the list from
# fab_pcb/packages/kicad-patches/build-macos.sh plus ccache).
# glslang, spirv-tools and spirv-cross compile the RHI shaders (SPIR-V, then MSL for the
# Metal backend); see cmake/RHIShaderCompilation.cmake.  sqlite: the build refuses the
# macOS SDK's SQLite (it cannot read WAL databases), so build.sh points SQLite3_ROOT at
# Homebrew's keg-only copy.
set -euo pipefail
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1

# wxwidgets@3.2 is the versioned formula build-macos.sh was written against; fall back to
# the unversioned one (>= 3.2 is all KiCad requires) if Homebrew has dropped it.
brew install wxwidgets@3.2 || brew install wxwidgets

brew install cmake ninja ccache pkg-config \
  boost protobuf nng glew glm cairo pixman harfbuzz freetype fontconfig gettext \
  opencascade libngspice unixodbc libgit2 zstd nlohmann-json \
  glslang spirv-tools spirv-cross sqlite

for tool in glslangValidator spirv-opt spirv-cross; do
  echo "$tool: $(command -v "$tool")"
done
echo "sqlite: $(brew --prefix sqlite)"
