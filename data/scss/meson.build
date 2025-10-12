scss_deps = files(
  '_bar.scss',
  '_colors.scss',
  '_menu.scss',
  '_osd.scss',
  '_player.scss',
  '_weather.scss',
  'main.scss',
)

scss = custom_target(
  'scss',
  input: 'main.scss',
  output: 'vanity.css',
  command: [find_program('sass'), '@INPUT@', '@OUTPUT@'],
  depend_files: scss_deps,
)
