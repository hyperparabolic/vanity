{
  description = "Vanity";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    astal,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        version = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./version);

        astal-libs = with astal.packages.${system}; [
          astal4
          battery
          bluetooth
          hyprland
          io
          mpris
          tray
          wireplumber
        ];
        build-tools = with pkgs; [
          meson
          ninja
        ];
        compiler-tools = with pkgs; [
          blueprint-compiler
          dart-sass
          gobject-introspection
          libxml2
          pkg-config
          uncrustify
          vala
          vala-lint
        ];
        local-libs = with self.packages.${system}; [
          libglycin
        ];
        runtime-deps = with pkgs; [
          # libglycin deps
          glycin-loaders
          libseccomp
          lcms2
          bubblewrap
        ];
        system-libs = with pkgs; [
          glib
          gtk4
          gtk4-layer-shell
          libadwaita
          wrapGAppsHook4
        ];

        vanity = pkgs.stdenv.mkDerivation {
          name = "vanity";
          src = ./.;
          version = version;

          meta = {
            homepage = "https://github.com/hyperparabolic/vanity";
            description = "vanity desktop shell";
            license = nixpkgs.lib.licenses.mit;
            mainProgram = "vanity";
            platforms = nixpkgs.lib.platforms.linux;
          };

          nativeBuildInputs =
            astal-libs
            ++ build-tools
            ++ compiler-tools
            ++ local-libs
            ++ system-libs;

          propagatedBuildInputs = runtime-deps;
        };

        shell = pkgs.mkShell {
          nativeBuildInputs =
            astal-libs
            ++ build-tools
            ++ compiler-tools
            ++ local-libs
            ++ runtime-deps
            ++ system-libs;
        };

        libglycin-shim = pkgs.callPackage ./nix/libglycin/libglycin-shim.nix {};
        libglycin = pkgs.callPackage ./nix/libglycin/libglycin.nix {inherit libglycin-shim;};
      in {
        packages.default = vanity;
        packages.libglycin-shim = libglycin-shim;
        packages.libglycin = libglycin;
        devShells.default = shell;
      }
    );
}
