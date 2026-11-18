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

  # The CEF build the `cef` crate in src/Cargo.lock is pinned to (156.4.0+156.0.26): libcef's API
  # hash must match the bindings, so nixpkgs' cef-binary (another release) can't stand in. Its
  # minimal tarball no longer ships libEGL/libGLESv2, which nixpkgs' installPhase patches, so this
  # repacks it here instead of overriding cef-binary.
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

      # cef-dll-sys wants one flat directory, as download-cef extracts it: the runtime (Release/ and
      # Resources/ merged), include/ for the API version, and an archive.json naming the release.
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

  # Opened at run time rather than linked: wgpu (Vulkan, EGL), the dma-buf probe (libEGL, libgbm,
  # libX11) and the Wayland/X11 backends.
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

  # The cmake/ninja hooks would take over configure; only cef-dll-sys' build script wants them.
  dontUseCmakeConfigure = true;
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;

  env = {
    CEF_PATH = cef;
    # Baked into the binary as CEF's resources and locales dir (linux_util::cef_paths).
    CEF_RESOURCES_DIR = cef;
    # Same rpath `cargo xtask build --cef-path` gives the AUR build; libmpv comes from pkg-config.
    JFN_EXTRA_RPATH = "${cef}:${lib.makeLibraryPath runtimeLibs}";
    JFN_GIT_HASH = builtins.substring 0 7 rev;
    JFN_GIT_DIRTY = "0";
  };

  # Needs a display, a GPU and CEF's subprocesses.
  doCheck = false;

  # mpv's scripts are looked up next to the real executable (current_exe()/mpv/scripts), so the
  # binary lives in libexec with them and bin/ only links to it.
  postInstall = ''
    mkdir -p $out/libexec/jellium-desktop
    mv $out/bin/jellium-desktop $out/libexec/jellium-desktop/
    cp -r resources/mpv $out/libexec/jellium-desktop/mpv
    ln -s $out/libexec/jellium-desktop/jellium-desktop $out/bin/jellium-desktop

    install -Dm644 resources/linux/net.nullsum.JelliumDesktop.desktop \
      $out/share/applications/net.nullsum.JelliumDesktop.desktop
    install -Dm644 resources/linux/net.nullsum.JelliumDesktop.svg \
      $out/share/icons/hicolor/scalable/apps/net.nullsum.JelliumDesktop.svg

    # cargoInstallHook also picks up the CEF runtime cef-dll-sys copies next to the build; the
    # binary loads it from ${cef} instead.
    rm -r $out/lib
  '';

  # patchelf --shrink-rpath would drop the dlopen()ed library dirs.
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
