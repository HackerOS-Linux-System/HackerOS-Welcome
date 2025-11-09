import os
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, GdkPixbuf

def build_ui(window):
    # HeaderBar dla profesjonalnego wyglądu
    header_bar = Adw.HeaderBar()
    header_bar.set_show_end_title_buttons(True)

    # Box dla title widget z logo i tytułem
    title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

    # Logo (mniejsze dla headera)
    logo_path = "/usr/share/HackerOS/ICONS/Plymouth-Icons/watermark.png"
    if os.path.exists(logo_path):
        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(logo_path, 32, 32)
        logo_image = Gtk.Image.new_from_pixbuf(pixbuf)
    else:
        logo_image = Gtk.Image()  # Puste jeśli nie znaleziono
    title_box.append(logo_image)

    # Tytuł (mniejszy font dla headera)
    title_label = Gtk.Label(label="Witaj w HackerOS!")
    title_label.set_markup("<span font='Arial bold 20'>Witaj w HackerOS!</span>")
    title_box.append(title_label)

    header_bar.set_title_widget(title_box)

    # Content box
    content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
    content_box.set_margin_top(20)
    content_box.set_margin_start(20)
    content_box.set_margin_end(20)
    content_box.set_margin_bottom(20)

    # Podtytuł (używany też do feedbacku)
    window.subtitle_label = Gtk.Label(label="Twój system do Gier i Etycznego Hakowania")
    window.subtitle_label.set_markup("<span font='Arial 18'>Twój system do Gier i Etycznego Hakowania</span>")
    window.subtitle_label.set_halign(Gtk.Align.CENTER)
    window.subtitle_label.get_style_context().add_class("subtitle")
    content_box.append(window.subtitle_label)

    # Separator
    separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
    separator.set_margin_start(10)
    separator.set_margin_end(10)
    content_box.append(separator)

    # ScrolledWindow dla przycisków, aby było scrollowalne jeśli potrzeba
    scrolled_window = Gtk.ScrolledWindow()
    scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scrolled_window.set_hexpand(True)
    scrolled_window.set_vexpand(True)
    content_box.append(scrolled_window)

    # Layout przycisków - FlowBox dla dynamicznego układu
    flow_box = Gtk.FlowBox()
    flow_box.set_column_spacing(15)
    flow_box.set_row_spacing(15)
    flow_box.set_margin_start(10)
    flow_box.set_margin_end(10)
    flow_box.set_margin_bottom(20)
    flow_box.set_homogeneous(True)
    flow_box.set_min_children_per_line(2)
    flow_box.set_max_children_per_line(3)
    scrolled_window.set_child(flow_box)

    # Pozostałe przyciski (usunięto wskazane)
    buttons = [
        ("Otwórz stronę HackerOS", window.actions.open_website),
        ("Otwórz X", window.actions.open_x),
        ("Otwórz sklep z aplikacjami", window.actions.open_software),
        ("Changelog", window.actions.open_changelog),
        ("Informacje o systemie", window.actions.open_system_info),
        ("Zgłoś błąd", window.actions.report_bug),
        ("Forum dyskusyjne", window.actions.open_forum),
        ("Zaktualizuj system", window.actions.update_system),
        ("Uruchom HackerOS Games", lambda: window.actions.run_command_with_feedback("/usr/share/HackerOS/Scripts/Bin/HackerOS-Games.sh")),
        ("Hacker Launcher", lambda: window.actions.run_command_with_feedback("/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher"))
    ]
    for text, action in buttons:
        btn = Gtk.Button(label=text)
        btn.connect("clicked", lambda widget, act=action: act())
        flow_box.append(btn)

    # Footer
    footer_label = Gtk.Label(label="© 2025 HackerOS Team | All rights reserved")
    footer_label.set_halign(Gtk.Align.CENTER)
    footer_label.get_style_context().add_class("footer")
    content_box.append(footer_label)

    # ToolbarView do integracji headera i contentu
    toolbar_view = Adw.ToolbarView()
    toolbar_view.add_top_bar(header_bar)
    toolbar_view.set_content(content_box)

    # Ustaw content okna
    window.set_content(toolbar_view)
