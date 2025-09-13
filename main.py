import sys
import os
import webbrowser
import subprocess
from PySide6.QtWidgets import QApplication, QWidget, QLabel, QPushButton, QVBoxLayout, QHBoxLayout, QFrame
from PySide6.QtGui import QPixmap, QFont
from PySide6.QtCore import Qt

class HackerOSWelcome(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("HackerOS Welcome")
        self.setGeometry(100, 100, 900, 650)
        self.setStyleSheet("background-color: #121212; color: white;")
        self.initUI()

    def initUI(self):
        main_layout = QVBoxLayout()
        top_layout = QHBoxLayout()

        # Logo
        self.logo_label = QLabel(self)
        pixmap = QPixmap("/usr/share/HackerOS/ICONS/HackerOS.png")
        self.logo_label.setPixmap(pixmap)
        self.logo_label.setFixedSize(120, 120)
        self.logo_label.setScaledContents(True)
        top_layout.addWidget(self.logo_label)

        # Title
        self.title_label = QLabel("Witaj w HackerOS!", self)
        self.title_label.setFont(QFont("Arial", 28, QFont.Bold))
        self.title_label.setAlignment(Qt.AlignCenter)
        top_layout.addWidget(self.title_label)

        main_layout.addLayout(top_layout)

        self.subtitle_label = QLabel("Twój system do Gier i Etycznego Hakowania", self)
        self.subtitle_label.setFont(QFont("Arial", 18))
        self.subtitle_label.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(self.subtitle_label)

        # Separator
        separator = QFrame()
        separator.setFrameShape(QFrame.HLine)
        separator.setFrameShadow(QFrame.Sunken)
        separator.setStyleSheet("background-color: #888; height: 2px;")
        main_layout.addWidget(separator)

        # Buttons layout
        buttons_layout = QHBoxLayout()
        left_buttons = QVBoxLayout()
        right_buttons = QVBoxLayout()

        button_style = """
            QPushButton {
                background-color: #1E1E1E;
                color: white;
                border: 2px solid #555;
                border-radius: 8px;
                padding: 10px;
                font-size: 14px;
            }
            QPushButton:hover {
                background-color: #333;
                border-color: #777;
            }
            QPushButton:pressed {
                background-color: #444;
            }
        """

        # Left side buttons
        buttons_left = [
            ("Sprawdź aktualizacje", self.checkUpdates),
            ("Uruchom narzędzia HackerOS", self.launchTools),
            ("Otwórz stronę HackerOS", lambda: webbrowser.open("https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html")),
            ("Otwórz X", lambda: webbrowser.open("https://x.com/hackeros_linux")),
            ("Otwórz dokumentację", self.openDocumentation),
            ("Uruchom Steam", self.launchSteam),
            ("Otwórz sklep z aplikacjami", self.openSoftware)
        ]
        for text, action in buttons_left:
            btn = QPushButton(text, self)
            btn.setStyleSheet(button_style)
            btn.clicked.connect(action)
            left_buttons.addWidget(btn)

        # Right side buttons
        buttons_right = [
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
        for text, cmd in buttons_right:
            btn = QPushButton(text, self)
            btn.setStyleSheet(button_style)
            btn.clicked.connect(lambda _, c=cmd: self.run_command_with_feedback(c))
            right_buttons.addWidget(btn)

        buttons_layout.addLayout(left_buttons)
        buttons_layout.addLayout(right_buttons)
        main_layout.addLayout(buttons_layout)
        self.setLayout(main_layout)

    def run_command_with_feedback(self, cmd):
        """Wspólna metoda do uruchamiania komend z feedbackiem."""
        full_cmd = f"bash -c '{cmd}'"
        result = os.system(f"pkexec {full_cmd}")
        if result == 0:
            self.subtitle_label.setText(f"Uruchomiono: {cmd.split()[0]}.")
        else:
            self.subtitle_label.setText(f"Błąd podczas uruchamiania: {cmd.split()[0]}.")

    def checkUpdates(self):
        result = os.system("pkexec bash -c 'apt update && apt upgrade -y && flatpak update'")
        if result == 0:
            self.subtitle_label.setText("Sprawdzenie aktualizacji zakończone pomyślnie.")
        else:
            self.subtitle_label.setText("Błąd podczas sprawdzania aktualizacji.")

    def launchTools(self):
        result = os.system("pkexec bash /usr/share/HackerOS/Scripts/Bin/install-tools.sh")
        if result == 0:
            self.subtitle_label.setText("Uruchomiono narzędzia HackerOS pomyślnie.")
        else:
            self.subtitle_label.setText("Błąd podczas uruchamiania narzędzi HackerOS.")

    def launchSteam(self):
        try:
            subprocess.run(["flatpak", "run", "com.valvesoftware.Steam", "-gamepadui"], check=True)
            self.subtitle_label.setText("Steam został uruchomiony w trybie gamepad UI.")
        except FileNotFoundError:
            os.system("flatpak install com.valvesoftware.Steam")
            try:
                subprocess.run(["steam", "-gamepadui"], check=True)
                self.subtitle_label.setText("Steam zainstalowany i uruchomiony.")
            except subprocess.CalledProcessError:
                self.subtitle_label.setText("Błąd podczas uruchamiania Steam po instalacji.")
        except subprocess.CalledProcessError:
            self.subtitle_label.setText("Wystąpił błąd podczas uruchamiania Steam.")

    def openSoftware(self):
        result = os.system("gnome-software &")
        self.subtitle_label.setText("Uruchomiono Sklep z aplikacjami.")

    def openDocumentation(self):
        result = os.system("pkexec bash /usr/share/HackerOS/Scripts/Bin/HackerOS-Documentation.sh")
        if result == 0:
            self.subtitle_label.setText("Otworzono dokumentację HackerOS.")
        else:
            self.subtitle_label.setText("Błąd podczas otwierania dokumentacji.")


if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = HackerOSWelcome()
    window.show()
    sys.exit(app.exec())
