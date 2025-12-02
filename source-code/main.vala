public class HackerOSWelcome : Adw.Application {
    public HackerOSWelcome() {
        Object(application_id: "org.hackeros.welcome", flags: ApplicationFlags.DEFAULT_FLAGS);
    }

    protected override void startup() {
        base.startup();
        Adw.StyleManager.get_default().color_scheme = Adw.ColorScheme.FORCE_DARK;
    }

    protected override void activate() {
        var window = new Adw.ApplicationWindow(this) {
            title = "HackerOS Welcome",
            default_width = 1000,
            default_height = 750,
            decorated = false // Use false for client-side decorations (CSD) with custom header bar
        };

        // Load CSS with improvements for prettier look
        var provider = new Gtk.CssProvider();
        provider.load_from_string("""
        window {
            background-color: #121212;
            color: white;
            border-radius: 12px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.5);
        }
        headerbar {
            background-color: #1E1E1E;
            border-bottom: 1px solid #333;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
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
        image {
            color: #FFFFFF; /* For symbolic icons */
        }
        """);

        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var actions = new Actions();
        build_ui(window, actions);
        window.present();
    }

    public static int main(string[] args) {
        return new HackerOSWelcome().run(args);
    }
}
