project('HackerOS-Welcome', 'vala', 'c',
    version: '0.7.0',
    license: 'GPL-3.0-or-later',
    meson_version: '>= 0.59.0'
)

dependencies = [
    dependency('gtk4'),
    dependency('libadwaita-1', version: '>=1.5'),
    dependency('glib-2.0'),
    dependency('gio-2.0'),
    dependency('libsoup-3.0'),
    dependency('cairo'),
    dependency('pango'),
    dependency('pangocairo'),
]

sources = files(
    'src/main.vala',
    'src/ui.vala',
    'src/actions.vala',
    'src/motd.vala',
    'src/api.vala',
    'src/cache.vala',
    'src/system_info.vala',
    'src/settings.vala',
    'src/downloader.vala',
    'src/export.vala',
)

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required: false)
dependencies += [m_dep]

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
