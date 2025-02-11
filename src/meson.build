subdir('bar')
subdir('lib')
subdir('menu')

project_resources += ['app.vala', 'main.vala']

executable(
  project_name,
  project_resources,
  dependencies: [
    dependency('astal-4-4.0'),
    dependency('astal-battery-0.1'),
    dependency('astal-hyprland-0.1'),
    dependency('astal-io-0.1'),
    dependency('astal-mpris-0.1'),
    dependency('astal-tray-0.1'),
    dependency('astal-wireplumber-0.1'),
    dependency('gio-2.0'),
    dependency('gio-unix-2.0'),
    dependency('glycin-1'),
    dependency('glycin-gtk4-1'),
    dependency('gtk4'),
    dependency('gtk4-layer-shell-0'),
    dependency('libadwaita-1'),
  ],
  link_args: ['-lm'],  # link math library
  install: true,
  install_dir: get_option('prefix') / get_option('bindir'),
)
