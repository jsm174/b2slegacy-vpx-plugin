# B2SLegacy VPX plugin

B2SLegacy renders `.directb2s` backglasses for Visual Pinball X. It is a port of
the B2S Backglass Server COM component to the VPX plugin API.

## Why it is no longer part of VPX

B2SLegacy used to ship with VPX next to the newer B2S plugin. It was removed in
favor of B2S, which renders the same `.directb2s` files better:

- **Rendering.** B2SLegacy is a close port of the original WinForms code. It
  composes every frame on the CPU, using GDI+ drawing reimplemented from Wine
  on top of SDL surfaces, then uploads the whole backglass to the GPU as one
  texture. B2S draws each image directly with the VPX renderer, so it no longer
  rebuilds and re-uploads the full backglass every frame.
- **Lights.** B2SLegacy only knows whether a lamp is on or off. It gets this
  by intercepting the `ChangedLamps`, `ChangedSolenoids` and `ChangedGIStrings`
  calls the table script makes to PinMAME. B2S reads lamp and output levels
  straight from the controller, so bulbs fade in and out as they do on the
  real machine.
- **Animation.** B2S has a better animation engine for mechs and reels,
  including rolling reels with intermediate frames.
- **Editing.** B2S lets you adjust lights and DMD placement in game and saves
  the changes back to the `.directb2s` file.

Only one B2S plugin can run at a time. If both are enabled, the second one
registers nothing.

This repository keeps B2SLegacy buildable for anyone who still wants it, for
example to compare behavior against the original B2S Server.

## Building

Two steps, like vpinball: `platforms/<platform>/external.sh` stages the
dependencies pinned in `platforms/config.sh` (SDL3, the VPX plugin SDK and
shared plugin sources, and the PinMAME plugin header), then CMake builds the
plugin and bundles everything into `build/b2slegacy/`. No vpinball source tree
is needed.

To build against a local vpinball checkout instead of the pinned commit, set
`VPINBALL_SOURCE_DIR` when running `external.sh`.

<details open>
<summary>macos-arm64</summary>

```shell
brew install cmake
platforms/macos-arm64/external.sh
cmake -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build -- -j$(sysctl -n hw.ncpu)
```
</details>

<details>
<summary>linux-x64 / linux-aarch64</summary>

```shell
sudo apt-get install -y build-essential cmake git pkg-config curl \
  libdrm-dev libgbm-dev libegl-dev libgl1-mesa-dev libwayland-dev libwayland-egl-backend-dev \
  libudev-dev libx11-dev libxcursor-dev libxi-dev libxss-dev libxtst-dev libxkbcommon-dev \
  libxrandr-dev libasound2-dev libpipewire-0.3-dev
platforms/linux-x64/external.sh
cmake -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build -- -j$(nproc)
```

Use `platforms/linux-aarch64/external.sh` for aarch64.
</details>

<details>
<summary>windows-x64 / windows-x86</summary>

Requires Visual Studio 2026 and Git Bash:

```shell
platforms/windows-x64/external.sh
cmake -G "Visual Studio 18 2026" -A x64 -B build
cmake --build build --config Release
```

Use `platforms/windows-x86/external.sh` and `-A Win32` for x86.
</details>

<details>
<summary>windows-mingw-x64</summary>

Inside an MSYS2 UCRT64 shell:

```shell
pacman -S --noconfirm --needed git curl tar \
  mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-make
platforms/windows-mingw-x64/external.sh
cmake -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build -- -j$(nproc)
```
</details>

### Static library (iOS, Android)

On iOS and Android the plugin has to be linked into libvpinball (see below).
Setting `PLATFORM` builds `build-<platform>/b2slegacy/libplugin-b2slegacy.a`.
SDL3 is not bundled, because the application provides it, so `external.sh` only
stages its headers.

<details>
<summary>ios-arm64 / ios-simulator-arm64</summary>

```shell
platforms/ios-arm64/external.sh
cmake -DPLATFORM=ios -DCMAKE_BUILD_TYPE=Release -B build-ios-arm64
cmake --build build-ios-arm64 -- -j$(sysctl -n hw.ncpu)
```

Use `platforms/ios-simulator-arm64/external.sh` and `-DPLATFORM=ios-simulator`
for the simulator.
</details>

<details>
<summary>android-arm64-v8a</summary>

```shell
export ANDROID_NDK_ROOT=<path to the NDK>
platforms/android-arm64-v8a/external.sh
cmake -DPLATFORM=android -DCMAKE_BUILD_TYPE=Release -B build-android-arm64-v8a
cmake --build build-android-arm64-v8a -- -j$(nproc)
```
</details>

`-DBUILD_STATIC=ON` without `PLATFORM` builds the same static library for the
host.

### Custom iOS / Android builds of VPX

iOS and Android cannot load plugins at runtime, and VPX does not ship
B2SLegacy, so using it there means making a custom libvpinball build that links
the static library and registers the plugin:

1. Build `libplugin-b2slegacy.a` for the target as shown above and copy it into
   the vpinball tree at `third-party/build-libs/<platform>-<arch>/`
   (`ios-arm64`, `ios-simulator-arm64` or `android-arm64-v8a`).

2. Link it into libvpinball in `make/CMakeLists_app.txt`, in the
   `ios` / `ios-simulator` / `android` branch, which already searches
   `third-party/build-libs/<platform>-<arch>`:

   ```cmake
   target_link_libraries(vpinball PUBLIC
      ...
      plugin-b2slegacy
   )
   ```

3. Register it with the other statically linked plugins in
   `lib/src/VPinballLib.cpp`:

   ```cpp
   MSGPI_EXPORT void MSGPIAPI B2SLegacyPluginLoad(const uint32_t sessionId, const MsgPluginAPI* api);
   MSGPI_EXPORT void MSGPIAPI B2SLegacyPluginUnload();
   ```

   ```cpp
   void VPinballLib::SetupStaticPlugins(MsgPI::MsgPluginManager& manager)
   {
      static constexpr struct {
         ...
      } plugins[] = {
         ...
         { "B2SLegacy",     &B2SLegacyPluginLoad,     &B2SLegacyPluginUnload     },
         ...
      };
   ```

The archive leaves its SDL3 symbols undefined; they resolve against the SDL3
libvpinball already links.

## Installing

Copy `build/b2slegacy/` into the VPX `plugins` folder and enable the plugin in
`VPinballX.ini`, disabling B2S since only one of them can run:

```ini
[Plugin.B2SLegacy]
Enable = 1

[Plugin.B2S]
Enable = 0
```

## License

GPLv3+, see `LICENSE`.
