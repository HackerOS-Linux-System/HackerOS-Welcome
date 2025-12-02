// actions.vala
public class Actions {
    public Gtk.Label? subtitle_label { get; set; }
    public weak Gtk.Window? parent_window { get; set; }

    private void update_subtitle(string text) {
        if (subtitle_label != null) {
            subtitle_label.label = text;
        }
    }

    public void open_website() {
        var launcher = new Gtk.UriLauncher("https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html");
        launcher.launch.begin (parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                update_subtitle("Otworzono stronę HackerOS.");
            } catch (Error e) {
                update_subtitle("Błąd podczas otwierania strony HackerOS.");
            }
        });
    }

    public void open_x() {
        var launcher = new Gtk.UriLauncher("https://x.com/hackeros_linux");
        launcher.launch.begin (parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                update_subtitle("Otworzono X.");
            } catch (Error e) {
                update_subtitle("Błąd podczas otwierania X.");
            }
        });
    }

    public void open_software() {
        try {
            GLib.Process.spawn_command_line_async("gnome-software");
            update_subtitle("Uruchomiono Sklep z aplikacjami.");
        } catch (Error e) {
            update_subtitle("Błąd podczas uruchamiania Sklep z aplikacjami.");
        }
    }

    public void open_changelog() {
        var launcher = new Gtk.UriLauncher("https://hackeros-linux-system.github.io/HackerOS-Website/releases.html");
        launcher.launch.begin (parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                update_subtitle("Otworzono Changelog.");
            } catch (Error e) {
                update_subtitle("Błąd podczas otwierania Changelog.");
            }
        });
    }

    public void open_system_info() {
        var launcher = new Gtk.UriLauncher("https://hackeros-linux-system.github.io/HackerOS-Website/about-hackeros.html");
        launcher.launch.begin (parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                update_subtitle("Otworzono Informacje o systemie.");
            } catch (Error e) {
                update_subtitle("Błąd podczas otwierania Informacje o systemie.");
            }
        });
    }

    public void report_bug() {
        var launcher = new Gtk.UriLauncher("https://github.com/HackerOS-Linux-System/HackerOS-Website/issues");
        launcher.launch.begin (parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                update_subtitle("Otworzono Zgłoś błąd.");
            } catch (Error e) {
                update_subtitle("Błąd podczas otwierania Zgłoś błąd.");
            }
        });
    }

    public void open_forum() {
        var launcher = new Gtk.UriLauncher("https://github.com/HackerOS-Linux-System/HackerOS-Website/discussions");
        launcher.launch.begin (parent_window, null, (obj, res) => {
            try {
                launcher.launch.end(res);
                update_subtitle("Otworzono Forum dyskusyjne.");
            } catch (Error e) {
                update_subtitle("Błąd podczas otwierania Forum dyskusyjne.");
            }
        });
    }

    public void update_system() {
        var terminal_cmd = "alacritty -e bash -c \"hacker update; read -p 'Chcesz zamknąć terminal? (t/n) ' answer; if [ \"$answer\" = 't' ]; then exit; else echo 'Terminal pozostanie otwarty.'; read; fi\"";
        try {
            GLib.Process.spawn_command_line_async(terminal_cmd);
            update_subtitle("Rozpoczęto aktualizację systemu w terminalu.");
        } catch (Error e) {
            update_subtitle("Błąd podczas uruchamiania aktualizacji systemu.");
        }
    }
}
