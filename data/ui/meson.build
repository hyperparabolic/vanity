blueprints = custom_target(
  'blueprints',
  input: files(
    'bar.blp',
    'confirmation-button.blp',
    'menu-idle.blp',
    'menu-selector.blp',
    'menu-system-controls.blp',
    'menu.blp',
  ),
  output: '.',
  command: [
    find_program('blueprint-compiler'),
    'batch-compile',
    '@OUTPUT@',
    '@CURRENT_SOURCE_DIR@',
    '@INPUT@',
  ],
)
