{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  rustPlatform,
  pkg-config,
  cmake,
  ninja,
  # CEF runtime
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxshmfence,
  nspr,
  nss,
  pango,
  systemdLibs,
  udev,
  # App
  ffmpeg,
  mpv-unwrapped,
  vulkan-loader,
  wayland,
}:

let
  version = "0.1.0-unstable-2026-11-15";
  rev = "09de0a6d8c3fe7620df71b469c78752892de12e4";

  # CEF build pinned by the `cef` crate in src/Cargo.lock (156.4.0+156.0.26); libcef's API hash
  # must match, so nixpkgs' cef-binary can't be used. Repacked here: the minimal tarball lacks
  # libEGL/libGLESv2, which nixpkgs' installPhase patches.
  cef =
    let
      cefVersion = "156.0.26";
      gitRevision = "8ea0c73";
      chromiumVersion = "156.0.8078.88";
      rpath = lib.makeLibraryPath [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        glib
        gtk3
        libdrm
        libgbm
        libGL
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        libxshmfence
        nspr
        nss
        pango
        systemdLibs
        udev
      ];
    in
    stdenv.mkDerivation {
      pname = "cef-binary";
      version = cefVersion;

      src = fetchurl {
        url = "https://cef-builds.spotifycdn.com/cef_binary_${cefVersion}+g${gitRevision}+chromium-${chromiumVersion}_linux64_minimal.tar.bz2";
        hash = "sha256-YArAuPN8uVP4hOfImZimwgDSSVmqdIIK1DG2HV6882A=";
      };

      dontConfigure = true;
      dontBuild = true;
      dontPatchELF = true;

      # Flat dir as download-cef extracts it: Release/ + Resources/ merged, include/, archive.json.
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r Release/. Resources/. $out/
        cp -r include $out/include
        patchelf --add-needed libudev.so --set-rpath "${rpath}" $out/libcef.so
        patchelf --set-rpath "${lib.makeLibraryPath [ stdenv.cc.cc ]}" \
          $out/libvk_swiftshader.so $out/libvulkan.so.1
        rm $out/chrome-sandbox
        echo '{"type":"minimal","name":"cef_binary_${cefVersion}","sha1":""}' > $out/archive.json

        runHook postInstall
      '';

      meta = {
        homepage = "https://cef-builds.spotifycdn.com/index.html";
        license = lib.licenses.bsd3;
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    };

  # dlopen()ed at run time: wgpu (Vulkan, EGL), dma-buf probe (libEGL, libgbm, libX11), Wayland/X11.
  runtimeLibs = [
    libGL
    libgbm
    libx11
    libxcb
    libxkbcommon
    vulkan-loader
    wayland
  ];
in
rustPlatform.buildRustPackage {
  pname = "jellium-desktop";
  inherit version;

  src = fetchFromGitHub {
    owner = "andrewrabert";
    repo = "jellium-desktop";
    inherit rev;
    hash = "sha256-LNpiM5vTtqjA8/YvHVgJ7cBvqgGzphUJm03sxHA9LZU=";
  };

  cargoRoot = "src";
  buildAndTestSubdir = "src/jfn_rust";
  cargoHash = "sha256-RMpYi6tCm2X5MuhXhU91kJomDwKoNwz/+9KscrUP8U0=";

  nativeBuildInputs = [
    pkg-config
    cmake
    ninja
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    ffmpeg
    mpv-unwrapped
  ]
  ++ runtimeLibs;

  # cmake/ninja are only for cef-dll-sys' build script; skip their hooks.
  dontUseCmakeConfigure = true;
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;

  env = {
    CEF_PATH = cef;
    # CEF resources/locales dir baked into the binary.
    CEF_RESOURCES_DIR = cef;
    # Same rpath as the AUR build (`cargo xtask build --cef-path`); libmpv via pkg-config.
    JFN_EXTRA_RPATH = "${cef}:${lib.makeLibraryPath runtimeLibs}";
    JFN_GIT_HASH = builtins.substring 0 7 rev;
    JFN_GIT_DIRTY = "0";
  };

  # Needs a display, a GPU and CEF's subprocesses.
  doCheck = false;

  # mpv scripts are found next to the real executable, so the binary lives in libexec; bin/ links it.
  postInstall = ''
    mkdir -p $out/libexec/jellium-desktop
    mv $out/bin/jellium-desktop $out/libexec/jellium-desktop/
    cp -r resources/mpv $out/libexec/jellium-desktop/mpv
    ln -s $out/libexec/jellium-desktop/jellium-desktop $out/bin/jellium-desktop

    install -Dm644 resources/linux/net.nullsum.JelliumDesktop.desktop \
      $out/share/applications/net.nullsum.JelliumDesktop.desktop
    install -Dm644 resources/linux/net.nullsum.JelliumDesktop.svg \
      $out/share/icons/hicolor/scalable/apps/net.nullsum.JelliumDesktop.svg

    # Drop the CEF runtime cef-dll-sys copies; the binary loads it from ${cef}.
    rm -r $out/lib
  '';

  # --shrink-rpath would drop the dlopen()ed library dirs.
  dontPatchELF = true;

  passthru = { inherit cef; };

  meta = {
    description = "Unofficial Jellyfin desktop client built on CEF and mpv";
    homepage = "https://github.com/andrewrabert/jellium-desktop";
    license = lib.licenses.gpl2Only;
    mainProgram = "jellium-desktop";
    platforms = [ "x86_64-linux" ];
  };
}
