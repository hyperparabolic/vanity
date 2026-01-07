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
        runtime-deps = with pkgs; [
          # libglycin deps
          glycin-loaders
          libseccomp
          lcms2
          bubblewrap
        ];
        system-libs = with pkgs; [
          geoclue2
          glib
          gtk4
          gtk4-layer-shell
          libadwaita
          libglycin
          libgweather
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
            ++ system-libs;

          propagatedBuildInputs = runtime-deps;
        };

        shell = pkgs.mkShell {
          nativeBuildInputs =
            astal-libs
            ++ build-tools
            ++ compiler-tools
            ++ runtime-deps
            ++ system-libs;
        };
      in {
        packages.default = vanity;
        devShells.default = shell;
      }
    );
}
