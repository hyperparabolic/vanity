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
          vala
        ];
        system-libs = with pkgs; [
          glib
          gtk4
          gtk4-layer-shell
          libadwaita
        ];

        vanity = pkgs.stdenv.mkDerivation {
          name = "vanity";
          src = ./.;
          version = version;

          buildInputs =
            astal-libs
            ++ build-tools
            ++ compiler-tools
            ++ system-libs;
        };

        shell = pkgs.mkShell {
          nativeBuildInputs =
            astal-libs
            ++ build-tools
            ++ compiler-tools
            ++ system-libs;
        };
      in {
        packages.default = vanity;
        devShells.default = shell;
      }
    );
}
