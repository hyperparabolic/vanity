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
  pname = "libglycin";
  version = "1.1.4";

  src = fetchurl {
    url = "mirror://gnome/sources/glycin/${lib.versions.majorMinor finalAttrs.version}/glycin-${finalAttrs.version}.tar.xz";
    hash = "sha256-0bbVkLaZtmgaZ9ARmKWBp/cQ2Mp0UJNN1/XbJB+hJQA=";
  };

  patches = [
    # Fix paths in glycin library.
    finalAttrs.passthru.glycinPathsPatch
    # Fix build bugs and only build libglycin, for use in next build
    finalAttrs.passthru.glycinShimPatch
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
      attrPath = "libglycin";
      packageName = "glycin";
    };

    glycinPathsPatch = replaceVars ./fix-glycin-paths.patch {
      bwrap = "${bubblewrap}/bin/bwrap";
    };

    glycinShimPatch = ./glycin-shim.patch;
  };

  meta = with lib; {
    description = "libglycin with vapi";
    homepage = "https://gitlab.gnome.org/GNOME/glycin";
    license = with licenses; [
      mpl20 # or
      lgpl21Plus
    ];
    platforms = platforms.linux;
  };
})
