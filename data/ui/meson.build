blueprints = custom_target(
  'blueprints',
  input: files('bar.blp', 'menu.blp', 'menu-selector.blp'),
  output: '.',
  command: [
    find_program('blueprint-compiler'),
    'batch-compile',
    '@OUTPUT@',
    '@CURRENT_SOURCE_DIR@',
    '@INPUT@',
  ],
)
