import sys
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio
from ui import build_ui
from actions import Actions

class HackerOSWelcome(Adw.ApplicationWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.actions = Actions(self)
        self.set_title("HackerOS Welcome")
        self.set_default_size(1000, 750)
        # Set dark theme using Adw.StyleManager
        style_manager = Adw.StyleManager.get_default()
        style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        # Stylizacja - rozbudowany CSS dla ładniejszego wyglądu
        self.style_provider = Gtk.CssProvider()
        css = """
        window {
            background-color: #121212;
            color: white;
            border-radius: 12px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.5);
        }
        label {
            color: white;
            text-shadow: 1px 1px 2px black;
        }
        button {
            background-color: #1E1E1E;
            color: white;
            border: 2px solid #555;
            border-radius: 8px;
            padding: 12px 20px;
            font-size: 16px;
            font-weight: bold;
            transition: all 0.3s ease;
        }
        button:hover {
            background-color: #333;
            border-color: #777;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
        }
        button:active {
            background-color: #444;
            box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.3);
        }
        .title {
            font-size: 32px;
            font-weight: bold;
            color: #FFFFFF;
        }
        .subtitle {
            font-size: 20px;
            color: #CCCCCC;
        }
        separator {
            background-color: #555;
            margin: 10px 0;
        }
        scrolledwindow {
            background-color: #181818;
            border-radius: 8px;
            padding: 10px;
        }
        .footer {
            font-size: 14px;
            color: #888888;
            padding: 10px;
            background-color: #0A0A0A;
            border-top: 1px solid #333;
        }
        """
        self.style_provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            self.style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        build_ui(self)

class Application(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.hackeros.welcome",
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        win = HackerOSWelcome(application=app)
        win.present()

if __name__ == '__main__':
    app = Application()
    app.run(sys.argv)
