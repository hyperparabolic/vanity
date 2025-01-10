subdir('bar')

project_resources += ['app.vala', 'main.vala']

executable(
  project_name,
  project_resources,
  dependencies: [
    dependency('astal-4-4.0'),
    dependency('astal-hyprland-0.1'),
    dependency('astal-io-0.1'),
    dependency('astal-tray-0.1'),
    dependency('astal-wireplumber-0.1'),
    dependency('gtk4'),
    dependency('gtk4-layer-shell-0'),
    dependency('libadwaita-1'),
  ],
  install: true,
)
