cmake_minimum_required(VERSION 3.24)

set(PLATFORM "" CACHE STRING "ios, ios-simulator or android to build the static library linked into libvpinball; empty for the host")

if(PLATFORM STREQUAL "ios" OR PLATFORM STREQUAL "ios-simulator")
	set(CMAKE_SYSTEM_NAME iOS)
	if(PLATFORM STREQUAL "ios-simulator")
		set(CMAKE_OSX_SYSROOT iphonesimulator)
	endif()
	set(CMAKE_OSX_DEPLOYMENT_TARGET 18.0)
	set(CMAKE_OSX_ARCHITECTURES arm64)
elseif(PLATFORM STREQUAL "android")
	set(CMAKE_SYSTEM_NAME Android)
	set(CMAKE_SYSTEM_VERSION 33)
	set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)
elseif(NOT PLATFORM STREQUAL "")
	message(FATAL_ERROR "Unsupported PLATFORM=${PLATFORM}; use ios, ios-simulator, android or leave it empty")
else()
	set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0 CACHE STRING "")
	set(CMAKE_OSX_ARCHITECTURES arm64 CACHE STRING "")
endif()

file(READ src/B2SLegacyVersion.h version)
string(REGEX MATCH "B2SLEGACY_PLUGIN_VERSION_MAJOR[ ]+([0-9]+)" _tmp ${version})
set(VERSION_MAJOR "${CMAKE_MATCH_1}")
string(REGEX MATCH "B2SLEGACY_PLUGIN_VERSION_MINOR[ ]+([0-9]+)" _tmp ${version})
set(VERSION_MINOR "${CMAKE_MATCH_1}")
string(REGEX MATCH "B2SLEGACY_PLUGIN_VERSION_PATCH[ ]+([0-9]+)" _tmp ${version})
set(VERSION_PATCH "${CMAKE_MATCH_1}")

project(b2slegacy_vpx_plugin VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}" LANGUAGES C CXX)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third-party/include/plugins/VPXPlugin.h")
	message(FATAL_ERROR
		"Staged VPX plugin SDK not found under third-party/include/plugins; "
		"run platforms/<platform>/external.sh first")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(PLATFORM STREQUAL "")
	option(BUILD_STATIC "Build a static library to link into the application instead of a loadable plugin" OFF)
else()
	set(BUILD_STATIC ON)
endif()

if(PLATFORM STREQUAL "ios")
	set(B2SLEGACY_PLATFORM "ios-arm64")
elseif(PLATFORM STREQUAL "ios-simulator")
	set(B2SLEGACY_PLATFORM "ios-simulator-arm64")
elseif(PLATFORM STREQUAL "android")
	set(B2SLEGACY_PLATFORM "android-arm64-v8a")
elseif(APPLE)
	set(B2SLEGACY_PLATFORM "macos-arm64")
	set(B2SLEGACY_SDL_MODULE "libSDL3.0.dylib")
elseif(MINGW)
	set(B2SLEGACY_PLATFORM "windows-mingw-x64")
	set(B2SLEGACY_SDL_MODULE "SDL364.dll")
elseif(WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(B2SLEGACY_PLATFORM "windows-x64")
	set(B2SLEGACY_SDL_MODULE "SDL364.dll")
elseif(WIN32)
	set(B2SLEGACY_PLATFORM "windows-x86")
	set(B2SLEGACY_SDL_MODULE "SDL3.dll")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
	set(B2SLEGACY_PLATFORM "linux-aarch64")
	set(B2SLEGACY_SDL_MODULE "libSDL3.so.0")
else()
	set(B2SLEGACY_PLATFORM "linux-x64")
	set(B2SLEGACY_SDL_MODULE "libSDL3.so.0")
endif()
set(B2SLEGACY_RUNTIME_LIBS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third-party/runtime-libs/${B2SLEGACY_PLATFORM}")

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third-party/include/SDL3/SDL.h")
	message(FATAL_ERROR "SDL3 headers not found; run platforms/${B2SLEGACY_PLATFORM}/external.sh first")
endif()

if(NOT BUILD_STATIC)
	find_library(B2SLEGACY_SDL_LIB
		NAMES SDL364 SDL3
		PATHS "${B2SLEGACY_RUNTIME_LIBS_DIR}"
		NO_DEFAULT_PATH
		NO_CMAKE_FIND_ROOT_PATH)
	if(NOT B2SLEGACY_SDL_LIB)
		message(FATAL_ERROR "SDL3 not found; run platforms/${B2SLEGACY_PLATFORM}/external.sh first")
	endif()
endif()

set(THIRD_PARTY_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/third-party/include")

set(B2SLEGACY_SOURCES
	src/B2SLegacyPlugin.cpp
	src/common.cpp
	src/Server.cpp
	src/DMDOverlay/DMDOverlay.cpp
	src/classes/AnimationInfo.cpp
	src/classes/B2SAnimation.cpp
	src/classes/B2SAnimationBase.cpp
	src/classes/B2SCollectData.cpp
	src/classes/B2SData.cpp
	src/classes/B2SPlayer.cpp
	src/classes/B2SReelDisplay.cpp
	src/classes/B2SScreen.cpp
	src/classes/B2SSettings.cpp
	src/classes/CollectData.cpp
	src/classes/ControlInfo.cpp
	src/classes/EntryAction.cpp
	src/classes/LEDAreaInfo.cpp
	src/classes/LEDDisplayDigitLocation.cpp
	src/classes/PictureBoxAnimation.cpp
	src/classes/PictureBoxAnimationEntry.cpp
	src/classes/Sound.cpp
	src/collections/AnimationCollection.cpp
	src/collections/ControlCollection.cpp
	src/collections/GenericDictionaryIgnoreCase.cpp
	src/collections/IlluminationGroupCollection.cpp
	src/collections/PictureBoxCollection.cpp
	src/collections/ReelBoxCollection.cpp
	src/collections/ReelDisplayReelBoxCollection.cpp
	src/collections/RunningAnimationsCollection.cpp
	src/collections/ZOrderCollection.cpp
	src/controls/B2SBaseBox.cpp
	src/controls/B2SLEDBox.cpp
	src/controls/B2SPictureBox.cpp
	src/controls/B2SReelBox.cpp
	src/controls/Control.cpp
	src/dream7/Dream7Display.cpp
	src/dream7/Segment.cpp
	src/dream7/SegmentList.cpp
	src/dream7/SegmentNumber.cpp
	src/forms/Form.cpp
	src/forms/FormBackglass.cpp
	src/forms/FormDMD.cpp
	src/utils/GraphicsPath.cpp
	src/utils/Matrix.cpp
	src/utils/PinMAMEAPI.cpp
	src/utils/Timer.cpp
	src/utils/VPXGraphics.cpp
	"${THIRD_PARTY_INCLUDE}/nixie/NixieLayoutFile.cpp"
	"${THIRD_PARTY_INCLUDE}/plugins/ResURIResolver.cpp"
	"${THIRD_PARTY_INCLUDE}/tinyxml2/tinyxml2.cpp")

if(BUILD_STATIC)
	add_library(B2SLegacyPlugin STATIC ${B2SLEGACY_SOURCES})
else()
	add_library(B2SLegacyPlugin MODULE ${B2SLEGACY_SOURCES})
endif()

target_include_directories(B2SLegacyPlugin PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/src"
	"${THIRD_PARTY_INCLUDE}")
if(NOT WIN32)
	target_compile_definitions(B2SLegacyPlugin PRIVATE
		"__forceinline=__attribute__((always_inline)) inline")
endif()

set(STAGE_DIR "${CMAKE_BINARY_DIR}/b2slegacy")

if(BUILD_STATIC)
	set_target_properties(B2SLegacyPlugin PROPERTIES
		OUTPUT_NAME "plugin-b2slegacy"
		POSITION_INDEPENDENT_CODE ON)

	add_custom_command(TARGET B2SLegacyPlugin POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E rm -rf "${STAGE_DIR}"
		COMMAND "${CMAKE_COMMAND}" -E make_directory "${STAGE_DIR}/licenses"
		COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:B2SLegacyPlugin>" "${STAGE_DIR}/"
		COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE" "${STAGE_DIR}/licenses/license.txt"
		COMMENT "Staging b2slegacy static library at ${STAGE_DIR}")
	return()
endif()

set_target_properties(B2SLegacyPlugin PROPERTIES PREFIX "" SKIP_BUILD_RPATH ON)
if(B2SLEGACY_PLATFORM STREQUAL "windows-x86")
	set_target_properties(B2SLegacyPlugin PROPERTIES OUTPUT_NAME "plugin-b2slegacy")
elseif(WIN32)
	set_target_properties(B2SLegacyPlugin PROPERTIES OUTPUT_NAME "plugin-b2slegacy64")
else()
	set_target_properties(B2SLegacyPlugin PROPERTIES OUTPUT_NAME "plugin-b2slegacy")
endif()
if(APPLE)
	set_target_properties(B2SLegacyPlugin PROPERTIES SUFFIX ".dylib")
	target_link_options(B2SLegacyPlugin PRIVATE "-Wl,-rpath,@loader_path")
elseif(MINGW)
	target_link_options(B2SLegacyPlugin PRIVATE -static -static-libgcc -static-libstdc++)
elseif(MSVC)
	set_target_properties(B2SLegacyPlugin PROPERTIES
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
	set(OPT_COMMON
		/Ob2
		/O2
		/Oi
		/fp:fast
		/fp:except-
		/Ot
		/GF
		/GS-
		/Gy
		/GR
		/Oy
		/GT
		/GL
		/w44005
		/Zc:__cplusplus
		/std:c++20
		$<$<STREQUAL:${B2SLEGACY_PLATFORM},windows-x86>:/arch:SSE2>
	)
	target_compile_options(B2SLegacyPlugin PRIVATE
		$<$<CONFIG:Release>:$<$<COMPILE_LANGUAGE:CXX>:${OPT_COMMON}>>
		$<$<CONFIG:Release>:$<$<COMPILE_LANGUAGE:C>:${OPT_COMMON}>>
	)
	target_link_options(B2SLegacyPlugin PRIVATE
		$<$<CONFIG:Release>:/INCREMENTAL:NO>
		$<$<CONFIG:Release>:/OPT:REF>
		$<$<CONFIG:Release>:/OPT:ICF>
		$<$<CONFIG:Release>:/LTCG>
	)
elseif(UNIX)
	target_link_options(B2SLegacyPlugin PRIVATE "-Wl,-rpath,$ORIGIN")
endif()

target_link_libraries(B2SLegacyPlugin PRIVATE "${B2SLEGACY_SDL_LIB}")

set(B2SLEGACY_SDL_LICENSE "${B2SLEGACY_RUNTIME_LIBS_DIR}/SDL3-LICENSE.txt")
foreach(dependency "${B2SLEGACY_RUNTIME_LIBS_DIR}/${B2SLEGACY_SDL_MODULE}" "${B2SLEGACY_SDL_LICENSE}")
	if(NOT EXISTS "${dependency}")
		message(FATAL_ERROR
			"Required staged dependency is missing: ${dependency}; "
			"rerun platforms/${B2SLEGACY_PLATFORM}/external.sh")
	endif()
endforeach()

add_custom_command(TARGET B2SLegacyPlugin POST_BUILD
	COMMAND "${CMAKE_COMMAND}" -E rm -rf "${STAGE_DIR}"
	COMMAND "${CMAKE_COMMAND}" -E make_directory "${STAGE_DIR}/licenses"
	COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_CURRENT_SOURCE_DIR}/src/plugin.cfg" "${STAGE_DIR}/plugin.cfg"
	COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:B2SLegacyPlugin>" "${STAGE_DIR}/"
	COMMAND "${CMAKE_COMMAND}" -E copy "${B2SLEGACY_RUNTIME_LIBS_DIR}/${B2SLEGACY_SDL_MODULE}" "${STAGE_DIR}/"
	COMMAND "${CMAKE_COMMAND}" -E copy "${B2SLEGACY_SDL_LICENSE}" "${STAGE_DIR}/licenses/"
	COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE" "${STAGE_DIR}/licenses/license.txt"
	COMMENT "Staging b2slegacy plugin folder at ${STAGE_DIR}")
