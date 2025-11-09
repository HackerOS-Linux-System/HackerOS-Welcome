import os
import webbrowser
import subprocess

class Actions:
    def __init__(self, window):
        self.window = window

    def run_command_with_feedback(self, cmd):
        """Uruchamianie komend z feedbackiem."""
        full_cmd = f"bash -c '{cmd}'"
        result = os.system(f"pkexec {full_cmd}")
        cmd_name = cmd.split('/')[-1] if '/' in cmd else cmd
        if result == 0:
            self.window.subtitle_label.set_label(f"Uruchomiono: {cmd_name}.")
        else:
            self.window.subtitle_label.set_label(f"Błąd podczas uruchamiania: {cmd_name}.")

    def open_website(self):
        webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html")
        self.window.subtitle_label.set_label("Otworzono stronę HackerOS.")

    def open_x(self):
        webbrowser.open("https://x.com/hackeros_linux")
        self.window.subtitle_label.set_label("Otworzono X.")

    def open_software(self):
        result = os.system("gnome-software &")
        self.window.subtitle_label.set_label("Uruchomiono Sklep z aplikacjami.")

    def open_changelog(self):
        webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/releases.html")
        self.window.subtitle_label.set_label("Otworzono Changelog.")

    def open_system_info(self):
        webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/about-hackeros.html")
        self.window.subtitle_label.set_label("Otworzono Informacje o systemie.")

    def report_bug(self):
        webbrowser.open("https://github.com/HackerOS-Linux-System/HackerOS-Website/issues")
        self.window.subtitle_label.set_label("Otworzono Zgłoś błąd.")

    def open_forum(self):
        webbrowser.open("https://github.com/HackerOS-Linux-System/HackerOS-Website/discussions")
        self.window.subtitle_label.set_label("Otworzono Forum dyskusyjne.")

    def update_system(self):
        # Otwiera terminal z komendą hacker update, potem pyta o zamknięcie
        terminal_cmd = 'alacritty -e bash -c "hacker update; read -p \'Chcesz zamknąć terminal? (t/n) \' answer; if [ \"$answer\" = \'t\' ]; then exit; else echo \'Terminal pozostanie otwarty.\'; read; fi"'
        result = os.system(terminal_cmd)
        if result == 0:
            self.window.subtitle_label.set_label("Rozpoczęto aktualizację systemu w terminalu.")
        else:
            self.window.subtitle_label.set_label("Błąd podczas uruchamiania aktualizacji systemu.")
