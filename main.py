import sys
import os
import webbrowser
import subprocess
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, GdkPixbuf, Gdk, GLib, Gio

class HackerOSWelcome(Gtk.ApplicationWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.set_title("HackerOS Welcome")
        self.set_default_size(900, 650)
        # Stylizacja
        self.style_provider = Gtk.CssProvider()
        css = """
        window {
            background-color: #121212;
            color: white;
        }
        label {
            color: white;
        }
        button {
            background-color: #1E1E1E;
            color: white;
            border: 2px solid #555;
            border-radius: 8px;
            padding: 10px;
            font-size: 14px;
        }
        button:hover {
            background-color: #333;
            border-color: #777;
        }
        button:active {
            background-color: #444;
        }
        """
        self.style_provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            self.style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        self.init_ui()

    def init_ui(self):
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.set_child(main_box)
        # Górny layout z logo i tytułem
        top_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        top_box.set_margin_top(20)
        top_box.set_margin_start(20)
        top_box.set_margin_end(20)
        # Logo
        logo_path = "/usr/share/HackerOS/ICONS/Plymouth-Icons/watermark.png"
        if os.path.exists(logo_path):
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(logo_path, 120, 120)
            self.logo_image = Gtk.Image.new_from_pixbuf(pixbuf)
        else:
            self.logo_image = Gtk.Image() # Puste jeśli nie znaleziono
        top_box.append(self.logo_image)
        # Tytuł
        title_label = Gtk.Label(label="Witaj w HackerOS!")
        title_label.set_markup("<span font='Arial bold 28'>Witaj w HackerOS!</span>")
        title_label.set_hexpand(True)
        title_label.set_halign(Gtk.Align.CENTER)
        top_box.append(title_label)
        main_box.append(top_box)
        # Podtytuł (używany też do feedbacku)
        self.subtitle_label = Gtk.Label(label="Twój system do Gier i Etycznego Hakowania")
        self.subtitle_label.set_markup("<span font='Arial 18'>Twój system do Gier i Etycznego Hakowania</span>")
        self.subtitle_label.set_halign(Gtk.Align.CENTER)
        main_box.append(self.subtitle_label)
        # Separator
        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        separator.set_margin_start(20)
        separator.set_margin_end(20)
        main_box.append(separator)
        # Layout przycisków - dwie kolumny
        buttons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        buttons_box.set_margin_start(20)
        buttons_box.set_margin_end(20)
        buttons_box.set_margin_bottom(20)
        left_buttons_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        right_buttons_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        # Przyciski lewej kolumny
        left_buttons = [
            ("Sprawdź aktualizacje", self.check_updates),
            ("Uruchom narzędzia HackerOS", self.launch_tools),
            ("Otwórz stronę HackerOS", lambda: webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html")),
            ("Otwórz X", lambda: webbrowser.open("https://x.com/hackeros_linux")),
            ("Otwórz dokumentację", self.open_documentation),
            ("Uruchom Steam", self.launch_steam),
            ("Otwórz sklep z aplikacjami", self.open_software),
            ("Changelog", lambda: webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/releases.html")),
            ("Informacje o systemie", lambda: webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/about-hackeros.html")),
            ("Zgłoś błąd", lambda: webbrowser.open("https://github.com/HackerOS-Linux-System/HackerOS-Website/issues")),
            ("Forum dyskusyjne", lambda: webbrowser.open("https://github.com/HackerOS-Linux-System/HackerOS-Website/discussions")),
            ("Zaktualizuj system", self.update_system)
        ]
        for text, action in left_buttons:
            btn = Gtk.Button(label=text)
            btn.connect("clicked", lambda widget, act=action: act())
            left_buttons_box.append(btn)
        # Przyciski prawej kolumny
        right_buttons = [
            ("Proton Updater", "/usr/share/HackerOS/Scripts/Bin/Proton-Updater.sh"),
            ("Switch to Hacker Mode", "/usr/share/HackerOS/Scripts/Bin/Switch_To_Hacker-Mode.sh"),
            ("HackerOS Cockpit", "/usr/share/HackerOS/Scripts/Bin/HackerOS-Cockpit.sh"),
            ("Update System", "/usr/share/HackerOS/Scripts/Bin/update_system.sh"),
            ("Check updates", "/usr/share/HackerOS/Scripts/Bin/check_updates_notify.sh"),
            ("Hacker Game", "love /usr/share/HackerOS/Scripts/Hacker-Games/hacker-game.love"),
            ("Starblaster", "/usr/share/HackerOS/Scripts/Hacker-Games/starblaster"),
            ("The Racer", "/usr/share/HackerOS/Scripts/Hacker-Games/The-Racer"),
            ("Hacker Launcher", "/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher")
        ]
        for text, cmd in right_buttons:
            btn = Gtk.Button(label=text)
            btn.connect("clicked", lambda widget, c=cmd: self.run_command_with_feedback(c))
            right_buttons_box.append(btn)
        buttons_box.append(left_buttons_box)
        buttons_box.append(right_buttons_box)
        main_box.append(buttons_box)

    def run_command_with_feedback(self, cmd):
        """Uruchamianie komend z feedbackiem."""
        full_cmd = f"bash -c '{cmd}'"
        result = os.system(f"pkexec {full_cmd}")
        cmd_name = cmd.split('/')[-1] if '/' in cmd else cmd
        if result == 0:
            self.subtitle_label.set_label(f"Uruchomiono: {cmd_name}.")
        else:
            self.subtitle_label.set_label(f"Błąd podczas uruchamiania: {cmd_name}.")

    def check_updates(self):
        result = os.system("pkexec bash -c 'apt update && apt upgrade -y && flatpak update -y'")
        if result == 0:
            self.subtitle_label.set_label("Sprawdzenie aktualizacji zakończone pomyślnie.")
        else:
            self.subtitle_label.set_label("Błąd podczas sprawdzania aktualizacji.")

    def launch_tools(self):
        result = os.system("pkexec bash /usr/share/HackerOS/Scripts/Bin/install-tools.sh")
        if result == 0:
            self.subtitle_label.set_label("Uruchomiono narzędzia HackerOS pomyślnie.")
        else:
            self.subtitle_label.set_label("Błąd podczas uruchamiania narzędzi HackerOS.")

    def open_documentation(self):
        result = os.system("pkexec bash /usr/share/HackerOS/Scripts/Bin/HackerOS-Documentation.sh")
        if result == 0:
            self.subtitle_label.set_label("Otworzono dokumentację HackerOS.")
        else:
            self.subtitle_label.set_label("Błąd podczas otwierania dokumentacji.")

    def launch_steam(self):
        try:
            subprocess.run(["flatpak", "run", "com.valvesoftware.Steam", "-gamepadui"], check=True)
            self.subtitle_label.set_label("Steam został uruchomiony w trybie gamepad UI.")
        except (FileNotFoundError, subprocess.CalledProcessError):
            self.subtitle_label.set_label("Instalowanie Steam...")
            install_result = os.system("flatpak install -y com.valvesoftware.Steam")
            if install_result == 0:
                try:
                    subprocess.run(["flatpak", "run", "com.valvesoftware.Steam", "-gamepadui"], check=True)
                    self.subtitle_label.set_label("Steam zainstalowany i uruchomiony.")
                except subprocess.CalledProcessError:
                    self.subtitle_label.set_label("Błąd podczas uruchamiania Steam po instalacji.")
            else:
                self.subtitle_label.set_label("Błąd podczas instalacji Steam.")

    def open_software(self):
        result = os.system("gnome-software &")
        self.subtitle_label.set_label("Uruchomiono Sklep z aplikacjami.")

    def update_system(self):
        # Otwiera terminal z komendą hacker update, potem pyta o zamknięcie
        terminal_cmd = 'gnome-terminal -- bash -c "hacker update; read -p \'Chcesz zamknąć terminal? (t/n) \' answer; if [ \"$answer\" = \'t\' ]; then exit; else echo \'Terminal pozostanie otwarty.\'; read; fi"'
        result = os.system(terminal_cmd)
        if result == 0:
            self.subtitle_label.set_label("Rozpoczęto aktualizację systemu w terminalu.")
        else:
            self.subtitle_label.set_label("Błąd podczas uruchamiania aktualizacji systemu.")

class Application(Gtk.Application):
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
