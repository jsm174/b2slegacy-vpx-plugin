#!/bin/bash

set -e

cd "$(dirname "$0")/../.."

source ./platforms/config.sh

echo "Staging B2SLegacy plugin dependencies (windows-mingw-x64)..."
if [ -n "${VPINBALL_SOURCE_DIR}" ]; then
   echo "  VPINBALL_SOURCE_DIR: ${VPINBALL_SOURCE_DIR} (unpinned)"
else
   echo "  VPINBALL_SHA: ${VPINBALL_SHA}"
fi
echo "  PINMAME_SHA: ${PINMAME_SHA}"
echo "  SDL_SHA: ${SDL_SHA}"
echo ""

NUM_PROCS=$(nproc)

RUNTIME_LIBS="third-party/runtime-libs/windows-mingw-x64"
WORK="external/windows-mingw-x64"

mkdir -p "${RUNTIME_LIBS}" "${WORK}"

#
# build SDL3
#

SDL_FOUND_SHA="$([ -f ${WORK}/SDL/cache.txt ] && cat ${WORK}/SDL/cache.txt || echo "")"

if [ "${SDL_SHA}" != "${SDL_FOUND_SHA}" ]; then
   echo "Building SDL3. Expected: ${SDL_SHA}, Found: ${SDL_FOUND_SHA}"

   rm -rf "${WORK}/SDL"
   mkdir "${WORK}/SDL"

   curl -sL "https://github.com/libsdl-org/SDL/archive/${SDL_SHA}.tar.gz" -o "${WORK}/SDL/SDL.tar.gz"
   (cd "${WORK}/SDL" && tar xzf SDL.tar.gz && mv "SDL-${SDL_SHA}" src)
   sed -i.bak 's/OUTPUT_NAME "SDL3"/OUTPUT_NAME "SDL364"/g' "${WORK}/SDL/src/CMakeLists.txt"

   cmake -S "${WORK}/SDL/src" \
      -B "${WORK}/SDL/build" \
      -DSDL_SHARED=ON \
      -DSDL_STATIC=OFF \
      -DSDL_TEST_LIBRARY=OFF \
      -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
   cmake --build "${WORK}/SDL/build" -- -j${NUM_PROCS}

   echo "${SDL_SHA}" > "${WORK}/SDL/cache.txt"
fi

rm -rf third-party/include/SDL3 "${RUNTIME_LIBS}"/*SDL364*
cp -r "${WORK}/SDL/src/include/SDL3" third-party/include/
cp "${WORK}/SDL/build/SDL364.dll" "${WORK}/SDL/build/libSDL364.dll.a" "${RUNTIME_LIBS}/"
cp "${WORK}/SDL/src/LICENSE.txt" "${RUNTIME_LIBS}/SDL3-LICENSE.txt"

#
# stage VPX plugin SDK and shared plugin sources
#

VPINBALL_SRC="${WORK}/vpinball/vpinball-${VPINBALL_SHA}"

if [ -n "${VPINBALL_SOURCE_DIR}" ]; then
   VPINBALL_SRC="${VPINBALL_SOURCE_DIR}"
   echo "Using local vpinball source: ${VPINBALL_SRC} (unpinned)"
else
   VPINBALL_FOUND_SHA="$([ -f ${WORK}/vpinball/cache.txt ] && cat ${WORK}/vpinball/cache.txt || echo "")"

   if [ "${VPINBALL_SHA}" != "${VPINBALL_FOUND_SHA}" ]; then
      echo "Downloading vpinball. Expected: ${VPINBALL_SHA}, Found: ${VPINBALL_FOUND_SHA}"

      rm -rf "${WORK}/vpinball"
      mkdir "${WORK}/vpinball"

      curl -sL "https://github.com/vpinball/vpinball/archive/${VPINBALL_SHA}.tar.gz" -o "${WORK}/vpinball/vpinball.tar.gz"
      (cd "${WORK}/vpinball" && tar xzf vpinball.tar.gz \
         "vpinball-${VPINBALL_SHA}/plugins/plugins" \
         "vpinball-${VPINBALL_SHA}/plugins/nixie" \
         "vpinball-${VPINBALL_SHA}/third-party/include/tinyxml2" \
         "vpinball-${VPINBALL_SHA}/third-party/include/simple-uri-parser" \
         "vpinball-${VPINBALL_SHA}/third-party/include/unordered_dense.h" \
         "vpinball-${VPINBALL_SHA}/third-party/include/stl.h" \
         && rm vpinball.tar.gz)

      echo "${VPINBALL_SHA}" > "${WORK}/vpinball/cache.txt"
   fi
fi

rm -rf third-party/include/plugins third-party/include/nixie third-party/include/tinyxml2 \
   third-party/include/simple-uri-parser third-party/include/unordered_dense.h third-party/include/stl.h
mkdir -p third-party/include/plugins third-party/include/nixie
cp "${VPINBALL_SRC}"/plugins/plugins/*.h third-party/include/plugins/
cp "${VPINBALL_SRC}/plugins/plugins/ResURIResolver.cpp" third-party/include/plugins/
cp "${VPINBALL_SRC}"/plugins/nixie/NixieLayoutFile.{h,cpp} third-party/include/nixie/
cp -r "${VPINBALL_SRC}/third-party/include/tinyxml2" third-party/include/
cp -r "${VPINBALL_SRC}/third-party/include/simple-uri-parser" third-party/include/
cp "${VPINBALL_SRC}"/third-party/include/{unordered_dense.h,stl.h} third-party/include/

#
# stage PinMAME plugin header
#

PINMAME_FOUND_SHA="$([ -f ${WORK}/pinmame/cache.txt ] && cat ${WORK}/pinmame/cache.txt || echo "")"

if [ "${PINMAME_SHA}" != "${PINMAME_FOUND_SHA}" ]; then
   echo "Downloading PinMAME plugin header. Expected: ${PINMAME_SHA}, Found: ${PINMAME_FOUND_SHA}"

   rm -rf "${WORK}/pinmame"
   mkdir "${WORK}/pinmame"

   curl -sfL "https://raw.githubusercontent.com/vpinball/pinmame/${PINMAME_SHA}/src/libpinmame/PinMAMEPlugin.h" -o "${WORK}/pinmame/PinMAMEPlugin.h"

   echo "${PINMAME_SHA}" > "${WORK}/pinmame/cache.txt"
fi

rm -rf third-party/include/pinmame
mkdir -p third-party/include/pinmame
cp "${WORK}/pinmame/PinMAMEPlugin.h" third-party/include/pinmame/

echo "staged ${RUNTIME_LIBS}"
