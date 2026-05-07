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
            default_width = 1100,
            default_height = 780,
            decorated = true
        };

        var provider = new Gtk.CssProvider();
        provider.load_from_string("""
        /* ── Global ─────────────────────────────────────────────────────────── */
        window, .window-frame {
            background-color: #0d0d0f;
            color: #e8e8ec;
        }

        /* ── Header Bar ─────────────────────────────────────────────────────── */
        headerbar {
            background-color: #111115;
            border-bottom: 1px solid rgba(255,255,255,0.08);
            box-shadow: 0 1px 0 rgba(255,255,255,0.04);
            min-height: 48px;
        }
        headerbar .title {
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 0.05em;
            color: #e8e8ec;
        }

        /* ── Sidebar (navigation) ───────────────────────────────────────────── */
        .sidebar {
            background-color: #111115;
            border-right: 1px solid rgba(255,255,255,0.06);
            padding: 12px 0;
        }
        .sidebar-item {
            background: transparent;
            border: none;
            border-radius: 8px;
            color: #8888a0;
            font-size: 13px;
            font-weight: 500;
            padding: 10px 16px;
            margin: 2px 8px;
            transition: all 0.15s ease;
        }
        .sidebar-item:hover {
            background-color: rgba(255,255,255,0.06);
            color: #c8c8d8;
        }
        .sidebar-item.active {
            background-color: rgba(255,255,255,0.08);
            color: #e8e8ec;
            border-left: 3px solid #aaaaaa;
            border-radius: 0 8px 8px 0;
            margin-left: 0;
            padding-left: 21px;
        }
        .sidebar-section-label {
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.12em;
            color: #555566;
            padding: 14px 16px 4px 16px;
        }
        .sidebar-separator {
            background-color: rgba(255,255,255,0.05);
            margin: 8px 12px;
        }

        /* ── Main content area ──────────────────────────────────────────────── */
        .content-area {
            background-color: #0d0d0f;
        }

        /* ── MOTD card ───────────────────────────────────────────────────────── */
        .motd-card {
            background: linear-gradient(135deg,
                rgba(255,255,255,0.04) 0%,
                rgba(255,255,255,0.02) 50%,
                rgba(0,0,0,0) 100%);
            border: 1px solid rgba(255,255,255,0.12);
            border-radius: 12px;
            padding: 20px 24px;
            margin-bottom: 20px;
        }
        .motd-header {
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.14em;
            color: #aaaaaa;
            margin-bottom: 8px;
        }
        .motd-text {
            font-family: "JetBrains Mono", "Fira Code", monospace;
            font-size: 13px;
            color: #a0a0b0;
            line-height: 1.7;
        }
        .motd-tip-label {
            font-size: 11px;
            color: #555566;
            font-style: italic;
            margin-top: 6px;
        }

        /* ── Welcome hero area ───────────────────────────────────────────────── */
        .hero-title {
            font-size: 36px;
            font-weight: 800;
            color: #ffffff;
            letter-spacing: -0.02em;
        }
        .hero-accent {
            font-size: 36px;
            font-weight: 800;
            color: #cccccc;
            letter-spacing: -0.02em;
        }
        .hero-subtitle {
            font-size: 15px;
            margin-top: 6px;
            color: #888899;
        }
        .distro-badge {
            background-color: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.15);
            border-radius: 20px;
            padding: 4px 12px;
            font-size: 12px;
            font-weight: 600;
            color: #aaaaaa;
        }

        /* ── Action button grid ─────────────────────────────────────────────── */
        .action-card {
            background-color: #16161c;
            border: 1px solid rgba(255,255,255,0.07);
            border-radius: 12px;
            padding: 18px 16px;
            transition: all 0.18s ease;
        }
        .action-card:hover {
            background-color: #1e1e26;
            border-color: rgba(255,255,255,0.18);
            box-shadow: 0 4px 16px rgba(0,0,0,0.3);
        }
        .action-card:active {
            background-color: rgba(255,255,255,0.05);
        }
        .action-icon {
            color: #bbbbbb;
        }
        .action-title {
            font-size: 14px;
            font-weight: 600;
            color: #dddde8;
        }
        .action-desc {
            font-size: 12px;
            color: #606078;
            margin-top: 2px;
        }

        /* ── Section heading ─────────────────────────────────────────────────── */
        .section-title {
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.12em;
            color: #555566;
            margin-bottom: 10px;
            margin-top: 4px;
        }

        /* ── Footer ─────────────────────────────────────────────────────────── */
        .footer-label {
            font-size: 12px;
            color: #444455;
        }

        /* ── Status bar ─────────────────────────────────────────────────────── */
        .status-bar {
            background-color: #080810;
            border-top: 1px solid rgba(255,255,255,0.05);
            padding: 6px 16px;
        }
        .status-text {
            font-family: "JetBrains Mono", monospace;
            font-size: 11px;
            color: #aaaaaa;
        }
        .status-dot {
            color: #888888;
        }

        /* ── Scrolled window ────────────────────────────────────────────────── */
        scrolledwindow {
            background-color: transparent;
        }
        scrolledwindow undershoot,
        scrolledwindow overshoot {
            background: none;
        }

        /* ── Separator ──────────────────────────────────────────────────────── */
        separator {
            background-color: rgba(255,255,255,0.05);
        }

        /* ── Label defaults ─────────────────────────────────────────────────── */
        label {
            color: #e8e8ec;
        }
        """);

        // GTK 4.12+ uses Gtk.style_context_add_provider_for_display (non-deprecated)
        // but for broad compatibility we keep the cast through the C function directly.
        Gtk.StyleContext.add_provider_for_display (  // vala-disable-line deprecated
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        var actions = new Actions();
        build_ui(window, actions);
        window.present();
    }

    public static int main(string[] args) {
        return new HackerOSWelcome().run(args);
    }
}
