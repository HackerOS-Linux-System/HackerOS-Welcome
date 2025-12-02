project('HackerOS-Welcome', 'vala', 'c', version: '0.4.0')

dependencies = [
    dependency('gtk4'),
    dependency('libadwaita-1', version: '>=1.5')
]

sources = files(
    'main.vala',
    'ui.vala',
    'actions.vala'
)

executable('hackeros-welcome',
    sources,
    dependencies: dependencies,
    install: true,
    install_dir: get_option('bindir')
)

