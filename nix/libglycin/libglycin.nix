# Adapted from https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/gl/glycin-loaders/package.nix#L79
{
  stdenv,
  lib,
  fetchurl,
  replaceVars,
  bubblewrap,
  cairo,
  cargo,
  fontconfig,
  git,
  gobject-introspection,
  gnome,
  gtk4,
  lcms2,
  libglycin-shim,
  libheif,
  libjxl,
  librsvg,
  libseccomp,
  libxml2,
  meson,
  ninja,
  pkg-config,
  rustc,
  vala,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libglycin-gtk4";
  version = "1.1.4";

  src = fetchurl {
    url = "mirror://gnome/sources/glycin/${lib.versions.majorMinor finalAttrs.version}/glycin-${finalAttrs.version}.tar.xz";
    hash = "sha256-0bbVkLaZtmgaZ9ARmKWBp/cQ2Mp0UJNN1/XbJB+hJQA=";
  };

  patches = [
    # Fix paths in glycin library.
    finalAttrs.passthru.glycinPathsPatch
    # Fix build bugs and add glycin-shim as dependency
    finalAttrs.passthru.glycinDepsPatch
  ];

  nativeBuildInputs = [
    cargo
    git
    meson
    ninja
    pkg-config
    rustc
    vala
  ];

  buildInputs = [
    gtk4 # for GdkTexture
    cairo
    fontconfig
    gobject-introspection
    lcms2
    libglycin-shim
    libheif
    libxml2 # for librsvg crate
    librsvg
    libseccomp
    libjxl
  ];

  mesonFlags = [
    "-Dglycin-loaders=true"
    "-Dlibglycin=true"
    "-Dvapi=true"
  ];

  passthru = {
    updateScript = gnome.updateScript {
      attrPath = "libglycin-gtk4";
      packageName = "glycin";
    };

    glycinPathsPatch = replaceVars ./fix-glycin-paths.patch {
      bwrap = "${bubblewrap}/bin/bwrap";
    };

    glycinDepsPatch = ./fix-glycin-deps.patch;
  };

  meta = with lib; {
    description = "libglycin-gtk4 with vapi";
    homepage = "https://gitlab.gnome.org/GNOME/glycin";
    license = with licenses; [
      mpl20 # or
      lgpl21Plus
    ];
    platforms = platforms.linux;
  };
})
