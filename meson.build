project(
  'vanity',
  ['vala', 'c'],
  version: run_command('cat', 'version').stdout().strip(),
  meson_version: '>= 1.5.0',
  default_options: ['warning_level=2', 'werror=false'],
)

gnome = import('gnome')

project_name = meson.project_name()
project_resources = []

subdir('data')
subdir('src')
