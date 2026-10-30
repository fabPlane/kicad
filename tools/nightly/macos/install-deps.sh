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
  boost protobuf glew glm cairo pixman harfbuzz freetype fontconfig gettext \
  opencascade libngspice unixodbc libgit2 zstd nlohmann-json \
  glslang spirv-tools spirv-cross sqlite

for tool in glslangValidator spirv-opt spirv-cross; do
  echo "$tool: $(command -v "$tool")"
done
echo "sqlite: $(brew --prefix sqlite)"

# nng: Homebrew moved to nng 2.0 (Oct 2026), which drops the 1.x API KiCad's libs/kinng is
# written against (nng/protocol/pubsub0/*.h, nng_pub0_open, ...).  Build the pinned 1.x
# release as a static, position-independent library instead; build.sh points the configure
# at it, so nothing ends up in the bundle.  A Homebrew nng 2 left on the machine would put
# its headers on the include path, so it is removed.
NNG_VERSION="${NNG_VERSION:-1.12.5}"
NNG_PREFIX="${NNG_PREFIX:-$HOME/.cache/kicad-nightly/nng-$NNG_VERSION}"
if brew list --versions nng >/dev/null 2>&1; then
  brew uninstall --ignore-dependencies nng
fi
if [ ! -f "$NNG_PREFIX/lib/libnng.a" ]; then
  src="$(mktemp -d)"
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v$NNG_VERSION" https://github.com/nanomsg/nng "$src"
  cmake -S "$src" -B "$src/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$NNG_PREFIX" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DNNG_TESTS=OFF -DNNG_TOOLS=OFF -DNNG_ENABLE_NNGCAT=OFF -DNNG_ENABLE_TLS=OFF
  cmake --build "$src/build"
  cmake --install "$src/build"
  rm -rf "$src"
fi
echo "nng: $NNG_PREFIX ($NNG_VERSION, static)"
