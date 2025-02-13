blueprints = custom_target(
  'blueprints',
  input: files(
    'bar.blp',
    'confirmation-button.blp',
    'menu-audio-row.blp',
    'menu-audio.blp',
    'menu-hud.blp',
    'menu-idle.blp',
    'menu-selector.blp',
    'menu-system-controls.blp',
    'menu.blp',
    'player.blp',
    'sync-marquee.blp',
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
