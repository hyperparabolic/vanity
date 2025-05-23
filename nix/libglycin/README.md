# Glycin - libglycin

[glycin](https://gitlab.gnome.org/GNOME/glycin) is a rust library that sandboxes loading images into gdk testures. Only the loaders are currently packaged in nixpkgs (for consumption by the rust native client library). I want to use the client library in vala, so this builds libglycin and the vapi bindings. 

## Build funkiness

libglycin is required to build libglycin-gtk4. The meson.build for libglycin doesn't allow these to be built separately. There are some patches and workarounds to get around this along with some nix specific mitigations detailed below.

### Patch details

- ./fix-glycin-paths.patch
  - Normal nix path fixes. Replaces the `bwrap` with a full nix store binary path, and modifies the cargo checksums to allow modifying vendored code.
- ./fix-glycin-env.patch
  - Preserve environment variables utilizing `environment()`.
  - Append `<builddir>/meson-uninstalled` to `PKG_CONFIG_PATH`, allowing built but not installed packages to be used in the build. This feature is experimental and best effort (detailed [here](https://mesonbuild.com/Pkgconfig-module.html)).
