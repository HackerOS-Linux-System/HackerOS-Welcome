project('HackerOS-Welcome', 'vala', 'c',
    version: '0.5.0',
    license: 'GPL-3.0-or-later',
    meson_version: '>= 0.59.0'
)

dependencies = [
    dependency('gtk4'),
    dependency('libadwaita-1', version: '>=1.5'),
    dependency('glib-2.0'),
]

sources = files(
    'src/main.vala',
    'src/ui.vala',
    'src/actions.vala',
    'src/motd.vala',
)

executable('hackeros-welcome',
    sources,
    dependencies: dependencies,
    install: true,
    install_dir: get_option('bindir')
)

# Install .desktop file
install_data(
    'data/org.hackeros.welcome.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# Install app icon (if present)
# install_data(
#     'images/hackeros-welcome.png',
#     install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '256x256', 'apps')
# )
