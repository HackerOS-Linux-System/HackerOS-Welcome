public class Actions : Object {
    /* Set by build_ui so action handlers can update the status bar. */
    public Gtk.Label? subtitle_label { get; set; }
    public weak Gtk.Window? parent_window { get; set; }

    // ── private helpers ──────────────────────────────────────────────────────

    private void set_status(string text) {
        if (subtitle_label != null)
            subtitle_label.label = "● " + text;
    }

    private void open_url(string url, string success_msg, string error_msg) {
        var launcher = new Gtk.UriLauncher(url);
        launcher.launch.begin(parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                set_status(success_msg);
            } catch (Error e) {
                set_status(error_msg + " (" + e.message + ")");
            }
        });
    }

    private void open_browser(string url, string success_msg) {
        // Prefer vivaldi, then xdg-open as fallback
        string[] browsers = { "vivaldi", "vivaldi-stable", "xdg-open" };
        foreach (string browser in browsers) {
            try {
                GLib.Process.spawn_command_line_async(browser + " " + url);
                set_status(success_msg);
                return;
            } catch (Error e) {
                continue;
            }
        }
        // Final fallback: GTK URI launcher
        open_url(url, success_msg, "Błąd podczas otwierania " + url);
    }

    // ── public actions ───────────────────────────────────────────────────────

    /** Otwiera oficjalną stronę HackerOS */
    public void open_website() {
        open_url(
            "https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html",
            "Otworzono stronę HackerOS.",
            "Błąd podczas otwierania strony HackerOS."
        );
    }

    /** Otwiera dokumentację systemu HackerOS w Vivaldigm lub innej przeglądarce */
    public void open_documentation() {
        open_browser(
            "https://hackeros-linux-system.github.io/HackerOS-Website/hackeros-documentation.html",
            "Otworzono dokumentację HackerOS."
        );
    }

    /** Otwiera dokumentację narzędzi HackerOS */
    public void open_tools_docs() {
        open_browser(
            "https://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/index.html",
            "Otworzono dokumentację narzędzi HackerOS."
        );
    }

    /** Otwiera X / Twitter HackerOS */
    public void open_x() {
        open_url(
            "https://x.com/hackeros_linux",
            "Otworzono X (Twitter).",
            "Błąd podczas otwierania X."
        );
    }

    /** Uruchamia GNOME Software (sklep z aplikacjami) */
    public void open_software() {
        try {
            GLib.Process.spawn_command_line_async("gnome-software");
            set_status("Uruchomiono Sklep z aplikacjami.");
        } catch (Error e) {
            set_status("Błąd podczas uruchamiania Sklep z aplikacjami: " + e.message);
        }
    }

    /** Otwiera stronę Changelog / Releases */
    public void open_changelog() {
        open_url(
            "https://hackeros-linux-system.github.io/HackerOS-Website/releases.html",
            "Otworzono Changelog.",
            "Błąd podczas otwierania Changelog."
        );
    }

    /** Otwiera stronę GitHub projektu */
    public void open_github() {
        open_url(
            "https://github.com/HackerOS-Linux-System",
            "Otworzono GitHub.",
            "Błąd podczas otwierania GitHub."
        );
    }

    /** Otwiera stronę "O HackerOS" */
    public void open_system_info() {
        open_url(
            "https://hackeros-linux-system.github.io/HackerOS-Website/about-hackeros.html",
            "Otworzono Informacje o systemie.",
            "Błąd podczas otwierania Informacje o systemie."
        );
    }

    /** Otwiera GitHub Issues do zgłaszania błędów */
    public void report_bug() {
        open_url(
            "https://github.com/HackerOS-Linux-System/HackerOS-Website/issues",
            "Otworzono stronę zgłaszania błędów.",
            "Błąd podczas otwierania trackera błędów."
        );
    }

    /** Otwiera GitHub Discussions */
    public void open_forum() {
        open_url(
            "https://github.com/HackerOS-Linux-System/HackerOS-Website/discussions",
            "Otworzono Forum dyskusyjne.",
            "Błąd podczas otwierania forum."
        );
    }

    /**
     * Uruchamia ~/.hackeros/hacker/update-system w terminalu.
     * Jeśli alacritty nie jest dostępny, próbuje konsole lub xterm.
     */
    public void update_system() {
        string home = Environment.get_home_dir();
        string binary = Path.build_filename(home, ".hackeros", "hacker", "update-system");
        string inner_cmd = "\"" + binary + "\"; echo; read -p 'Naciśnij Enter, aby zamknąć terminal…'";

        string[] terminals = {
            "alacritty -e bash -c",
            "konsole -e bash -c",
            "xterm -e bash -c",
        };

        foreach (string term in terminals) {
            try {
                GLib.Process.spawn_command_line_async(
                    term + " '" + inner_cmd + "'"
                );
                set_status("Uruchomiono aktualizację systemu w terminalu.");
                return;
            } catch (Error e) {
                continue;
            }
        }
        set_status("Błąd: nie znaleziono obsługiwanego terminala.");
    }
}
