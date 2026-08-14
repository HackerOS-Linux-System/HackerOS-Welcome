public class AppSettings : Object {
    private const string GROUP = "General";
    private string config_dir;
    private string settings_path;
    private string state_path;

    public string preferred_source { get; set; default = "sf"; }   // sf | mega | drive | transfer | actions
    public string doc_lang_primary { get; set; default = "pl"; }   // pl | en | de
    public bool autostart_enabled { get; set; default = false; }

    public AppSettings() {
        config_dir = Path.build_filename(Environment.get_home_dir(), ".config", "hackeros-welcome");
        DirUtils.create_with_parents(config_dir, 0755);
        settings_path = Path.build_filename(config_dir, "settings.ini");
        state_path = Path.build_filename(config_dir, "state");
        load();
    }

    // ── Ustawienia (settings.ini) ────────────────────────────────────────

    public void load() {
        if (!FileUtils.test(settings_path, FileTest.EXISTS)) return;
        try {
            var kf = new KeyFile();
            kf.load_from_file(settings_path, KeyFileFlags.NONE);
            if (kf.has_key(GROUP, "preferred_source")) {
                preferred_source = kf.get_string(GROUP, "preferred_source");
            }
            if (kf.has_key(GROUP, "doc_lang_primary")) {
                doc_lang_primary = kf.get_string(GROUP, "doc_lang_primary");
            }
            if (kf.has_key(GROUP, "autostart_enabled")) {
                autostart_enabled = kf.get_boolean(GROUP, "autostart_enabled");
            }
        } catch (Error e) {
            /* Brak/uszkodzony plik ustawień — zostajemy przy wartościach domyślnych. */
        }
    }

    public void save() {
        var kf = new KeyFile();
        kf.set_string(GROUP, "preferred_source", preferred_source);
        kf.set_string(GROUP, "doc_lang_primary", doc_lang_primary);
        kf.set_boolean(GROUP, "autostart_enabled", autostart_enabled);
        try {
            kf.save_to_file(settings_path);
        } catch (Error e) {
            /* Brak uprawnień do zapisu — cicho ignorujemy. */
        }
    }

    /* Zwraca kolejność źródeł pobierania z ulubionym źródłem na początku. */
    public string[] source_order() {
        string[] all = { "sf", "mega", "drive", "transfer", "actions" };
        var result = new GenericArray<string>();
        result.add(preferred_source);
        foreach (var s in all) {
            if (s != preferred_source) result.add(s);
        }
        return result.data;
    }

    /* Zwraca kolejność fallbacku językowego dokumentacji z preferowanym językiem na początku. */
    public string[] doc_lang_order() {
        string[] all = { "pl", "en", "de" };
        var result = new GenericArray<string>();
        result.add(doc_lang_primary);
        foreach (var s in all) {
            if (s != doc_lang_primary) result.add(s);
        }
        return result.data;
    }

    // ── Stan: ostatnio otwarta zakładka ──────────────────────────────────

    public string load_last_tab(string fallback) {
        if (!FileUtils.test(state_path, FileTest.EXISTS)) return fallback;
        try {
            string contents;
            FileUtils.get_contents(state_path, out contents);
            string tab = contents.strip();
            return (tab != "") ? tab : fallback;
        } catch (Error e) {
            return fallback;
        }
    }

    public void save_last_tab(string tab) {
        try {
            FileUtils.set_contents(state_path, tab);
        } catch (Error e) {
            /* Cicho ignorujemy — to tylko wygoda, nie krytyczna funkcja. */
        }
    }

    // ── Autostart (XDG autostart .desktop) ───────────────────────────────

    private string autostart_dir() {
        return Path.build_filename(Environment.get_home_dir(), ".config", "autostart");
    }

    private string autostart_desktop_path() {
        return Path.build_filename(autostart_dir(), "org.hackeros.welcome.desktop");
    }

    public bool is_autostart_active() {
        return FileUtils.test(autostart_desktop_path(), FileTest.EXISTS);
    }

    /* Włącza lub wyłącza autostart aplikacji, kopiując/usuwając plik .desktop
     * w ~/.config/autostart/. Szuka oryginalnego pliku .desktop w typowych
     * lokalizacjach systemowych (zainstalowana aplikacja) i, jeśli go nie
     * znajdzie, tworzy minimalny wpis wywołujący `hackeros-welcome`. */
    public bool set_autostart(bool enabled) {
        string target = autostart_desktop_path();

        if (!enabled) {
            if (FileUtils.test(target, FileTest.EXISTS)) {
                FileUtils.remove(target);
            }
            autostart_enabled = false;
            save();
            return true;
        }

        DirUtils.create_with_parents(autostart_dir(), 0755);

        string[] candidates = {
            "/usr/share/applications/org.hackeros.welcome.desktop",
            "/usr/local/share/applications/org.hackeros.welcome.desktop"
        };

        string content = "";
        foreach (var path in candidates) {
            if (FileUtils.test(path, FileTest.EXISTS)) {
                try {
                    FileUtils.get_contents(path, out content);
                    break;
                } catch (Error e) {}
            }
        }

        if (content == "") {
            content = """[Desktop Entry]
Type=Application
Name=HackerOS Welcome
Exec=hackeros-welcome
Icon=org.hackeros.welcome
Terminal=false
X-GNOME-Autostart-enabled=true
""";
        } else if (!content.contains("X-GNOME-Autostart-enabled")) {
            content += "X-GNOME-Autostart-enabled=true\n";
        }

        try {
            FileUtils.set_contents(target, content);
        } catch (Error e) {
            return false;
        }

        autostart_enabled = true;
        save();
        return true;
    }
}
