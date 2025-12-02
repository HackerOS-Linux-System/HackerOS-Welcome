use gtk::Label;
use std::process::Command;
use webbrowser;

pub struct Actions {
    pub subtitle_label: Option<Label>,
}

impl Actions {
    pub fn new() -> Self {
        Actions {
            subtitle_label: None,
        }
    }

    fn update_subtitle(&self, text: &str) {
        if let Some(label) = &self.subtitle_label {
            label.set_label(text);
        }
    }

    pub fn open_website(&self) {
        if webbrowser::open("https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html").is_ok() {
            self.update_subtitle("Otworzono stronę HackerOS.");
        }
    }

    pub fn open_x(&self) {
        if webbrowser::open("https://x.com/hackeros_linux").is_ok() {
            self.update_subtitle("Otworzono X.");
        }
    }

    pub fn open_software(&self) {
        if Command::new("gnome-software").spawn().is_ok() {
            self.update_subtitle("Uruchomiono Sklep z aplikacjami.");
        } else {
            self.update_subtitle("Błąd podczas uruchamiania Sklep z aplikacjami.");
        }
    }

    pub fn open_changelog(&self) {
        if webbrowser::open("https://hackeros-linux-system.github.io/HackerOS-Website/releases.html").is_ok() {
            self.update_subtitle("Otworzono Changelog.");
        }
    }

    pub fn open_system_info(&self) {
        if webbrowser::open("https://hackeros-linux-system.github.io/HackerOS-Website/about-hackeros.html").is_ok() {
            self.update_subtitle("Otworzono Informacje o systemie.");
        }
    }

    pub fn report_bug(&self) {
        if webbrowser::open("https://github.com/HackerOS-Linux-System/HackerOS-Website/issues").is_ok() {
            self.update_subtitle("Otworzono Zgłoś błąd.");
        }
    }

    pub fn open_forum(&self) {
        if webbrowser::open("https://github.com/HackerOS-Linux-System/HackerOS-Website/discussions").is_ok() {
            self.update_subtitle("Otworzono Forum dyskusyjne.");
        }
    }

    pub fn update_system(&self) {
        let terminal_cmd = "alacritty -e bash -c \"hacker update; read -p 'Chcesz zamknąć terminal? (t/n) ' answer; if [ \"$answer\" = 't' ]; then exit; else echo 'Terminal pozostanie otwarty.'; read; fi\"";
        let result = Command::new("sh")
        .arg("-c")
        .arg(terminal_cmd)
        .status();

        match result {
            Ok(status) if status.success() => self.update_subtitle("Rozpoczęto aktualizację systemu w terminalu."),
            _ => self.update_subtitle("Błąd podczas uruchamiania aktualizacji systemu."),
        }
    }
}
