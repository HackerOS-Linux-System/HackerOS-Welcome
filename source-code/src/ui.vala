private Gtk.Button create_nav_button(string icon_name, string label_text) {
    var btn = new Gtk.Button();
    btn.add_css_class("sidebar-item");
    btn.halign = Gtk.Align.FILL;

    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    hbox.margin_start = 4;

    var icon = new Gtk.Image.from_icon_name(icon_name) { pixel_size = 18 };
    icon.valign = Gtk.Align.CENTER;
    hbox.append(icon);

    var lbl = new Gtk.Label(label_text);
    lbl.halign = Gtk.Align.START;
    lbl.hexpand = true;
    hbox.append(lbl);

    btn.child = hbox;
    return btn;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: create an action card (button in the grid)
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Button create_action_card(string icon_name, string title, string description) {
    var btn = new Gtk.Button();
    btn.add_css_class("action-card");

    var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
    vbox.margin_start = 4;
    vbox.margin_end = 4;

    var icon = new Gtk.Image.from_icon_name(icon_name) { pixel_size = 28 };
    icon.halign = Gtk.Align.START;
    icon.add_css_class("action-icon");
    vbox.append(icon);

    var title_lbl = new Gtk.Label(title);
    title_lbl.halign = Gtk.Align.START;
    title_lbl.add_css_class("action-title");
    title_lbl.wrap = true;
    vbox.append(title_lbl);

    var desc_lbl = new Gtk.Label(description);
    desc_lbl.halign = Gtk.Align.START;
    desc_lbl.add_css_class("action-desc");
    desc_lbl.wrap = true;
    vbox.append(desc_lbl);

    btn.child = vbox;
    return btn;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: section title label
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Label section_label(string text) {
    var lbl = new Gtk.Label(text.up());
    lbl.halign = Gtk.Align.START;
    lbl.add_css_class("section-title");
    return lbl;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "Home" page
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_home_page(Actions actions, Gtk.Label status_label) {
    var scroll = new Gtk.ScrolledWindow() {
        hscrollbar_policy = Gtk.PolicyType.NEVER,
        vexpand = true,
        hexpand = true
    };

    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        margin_start = 32,
        margin_end = 32,
        margin_top = 28,
        margin_bottom = 28
    };

    // ── Hero ────────────────────────────────────────────────────────────────
    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    hero_box.margin_bottom = 24;

    // Title row
    var title_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    title_row.valign = Gtk.Align.CENTER;

    var title_lbl = new Gtk.Label("Witaj w ");
    title_lbl.add_css_class("hero-title");

    var accent_lbl = new Gtk.Label("HackerOS");
    accent_lbl.add_css_class("hero-accent");

    var title_end = new Gtk.Label("!");
    title_end.add_css_class("hero-title");

    title_row.append(title_lbl);
    title_row.append(accent_lbl);
    title_row.append(title_end);

    // Distro variant badge
    string variant = read_distro_variant();
    var badge = new Gtk.Label("Wariant: " + variant);
    badge.halign = Gtk.Align.START;
    badge.add_css_class("distro-badge");
    badge.margin_top = 4;

    var sub_lbl = new Gtk.Label("Twój system jest gotowy. Poniżej znajdziesz szybki dostęp do najważniejszych funkcji.");
    sub_lbl.halign = Gtk.Align.START;
    sub_lbl.add_css_class("hero-subtitle");
    sub_lbl.wrap = true;

    hero_box.append(title_row);
    hero_box.append(badge);
    hero_box.append(sub_lbl);
    page.append(hero_box);

    // ── MOTD card ────────────────────────────────────────────────────────────
    string? motd = MotdLoader.load();
    if (motd != null) {
        var motd_card = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        motd_card.add_css_class("motd-card");
        motd_card.margin_bottom = 24;

        var motd_header = new Gtk.Label("// WIADOMOŚĆ DNIA");
        motd_header.halign = Gtk.Align.START;
        motd_header.add_css_class("motd-header");
        motd_card.append(motd_header);

        var motd_text = new Gtk.Label(motd);
        motd_text.halign = Gtk.Align.START;
        motd_text.wrap = true;
        motd_text.selectable = true;
        motd_text.add_css_class("motd-text");
        motd_card.append(motd_text);

        page.append(motd_card);
    }

    // ── Quick actions ─────────────────────────────────────────────────────────
    page.append(section_label("Szybkie akcje"));

    var grid = new Gtk.Grid() {
        column_spacing = 12,
        row_spacing = 12,
        column_homogeneous = true,
        margin_top = 8,
        margin_bottom = 24
    };

    // Row 0
    var btn_website = create_action_card(
        "applications-internet-symbolic",
        "Strona HackerOS",
        "Odwiedź oficjalną stronę projektu"
    );
    btn_website.clicked.connect(() => {
        actions.open_website();
        status_label.label = "● Otworzono stronę HackerOS";
    });
    grid.attach(btn_website, 0, 0, 1, 1);

    var btn_docs = create_action_card(
        "accessories-text-editor-symbolic",
        "Dokumentacja",
        "Pełna dokumentacja systemu HackerOS"
    );
    btn_docs.clicked.connect(() => {
        actions.open_documentation();
        status_label.label = "● Otworzono dokumentację";
    });
    grid.attach(btn_docs, 1, 0, 1, 1);

    var btn_tools = create_action_card(
        "utilities-terminal-symbolic",
        "Dokumentacja narzędzi",
        "Narzędzia i skrypty HackerOS"
    );
    btn_tools.clicked.connect(() => {
        actions.open_tools_docs();
        status_label.label = "● Otworzono dokumentację narzędzi";
    });
    grid.attach(btn_tools, 2, 0, 1, 1);

    // Row 1
    var btn_software = create_action_card(
        "system-software-install-symbolic",
        "Sklep z aplikacjami",
        "Przeglądaj i instaluj oprogramowanie"
    );
    btn_software.clicked.connect(() => {
        actions.open_software();
        status_label.label = "● Uruchomiono sklep z aplikacjami";
    });
    grid.attach(btn_software, 0, 1, 1, 1);

    var btn_update = create_action_card(
        "system-software-update-symbolic",
        "Aktualizuj system",
        "Pobierz najnowsze aktualizacje HackerOS"
    );
    btn_update.clicked.connect(() => {
        actions.update_system();
        status_label.label = "● Uruchomiono aktualizację systemu…";
    });
    grid.attach(btn_update, 1, 1, 1, 1);

    var btn_bug = create_action_card(
        "dialog-warning-symbolic",
        "Zgłoś błąd",
        "Pomóż nam ulepszać HackerOS"
    );
    btn_bug.clicked.connect(() => {
        actions.report_bug();
        status_label.label = "● Otworzono tracker błędów";
    });
    grid.attach(btn_bug, 2, 1, 1, 1);

    page.append(grid);

    // ── Community ─────────────────────────────────────────────────────────────
    page.append(section_label("Społeczność"));

    var community_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
        margin_top = 8,
        margin_bottom = 8,
        homogeneous = true
    };

    var btn_x = create_action_card(
        "internet-chat-symbolic",
        "X / Twitter",
        "Obserwuj @hackeros_linux"
    );
    btn_x.clicked.connect(() => {
        actions.open_x();
        status_label.label = "● Otworzono X (Twitter)";
    });
    community_box.append(btn_x);

    var btn_forum = create_action_card(
        "internet-group-chat-symbolic",
        "Forum dyskusyjne",
        "GitHub Discussions HackerOS"
    );
    btn_forum.clicked.connect(() => {
        actions.open_forum();
        status_label.label = "● Otworzono forum dyskusyjne";
    });
    community_box.append(btn_forum);

    var btn_changelog = create_action_card(
        "document-properties-symbolic",
        "Changelog",
        "Co nowego w tej wersji?"
    );
    btn_changelog.clicked.connect(() => {
        actions.open_changelog();
        status_label.label = "● Otworzono changelog";
    });
    community_box.append(btn_changelog);

    page.append(community_box);

    scroll.set_child(page);
    return scroll;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "Dokumentacja" page  (simple launcher page)
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_docs_page(Actions actions, Gtk.Label status_label) {
    var scroll = new Gtk.ScrolledWindow() {
        hscrollbar_policy = Gtk.PolicyType.NEVER,
        vexpand = true,
        hexpand = true
    };

    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        margin_start = 32,
        margin_end = 32,
        margin_top = 28,
        margin_bottom = 28
    };

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 28 };

    var title = new Gtk.Label("Dokumentacja");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);

    var sub = new Gtk.Label("Oficjalna dokumentacja HackerOS dostępna online.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    sub.wrap = true;
    hero_box.append(sub);
    page.append(hero_box);

    page.append(section_label("Dokumentacja systemu"));

    var grid = new Gtk.Grid() {
        column_spacing = 12,
        row_spacing = 12,
        column_homogeneous = true,
        margin_top = 8,
        margin_bottom = 24
    };

    var btn_sys_docs = create_action_card(
        "help-contents-symbolic",
        "Dokumentacja HackerOS",
        "Przewodnik użytkownika, konfiguracja, FAQ"
    );
    btn_sys_docs.clicked.connect(() => {
        actions.open_documentation();
        status_label.label = "● Otworzono dokumentację systemu";
    });
    grid.attach(btn_sys_docs, 0, 0, 1, 1);

    var btn_tools_docs = create_action_card(
        "utilities-terminal-symbolic",
        "Dokumentacja narzędzi",
        "Narzędzia CLI i skrypty wbudowane w HackerOS"
    );
    btn_tools_docs.clicked.connect(() => {
        actions.open_tools_docs();
        status_label.label = "● Otworzono dokumentację narzędzi";
    });
    grid.attach(btn_tools_docs, 1, 0, 1, 1);

    var btn_changelog2 = create_action_card(
        "document-properties-symbolic",
        "Changelog / Historia zmian",
        "Sprawdź co się zmieniło w nowych wersjach"
    );
    btn_changelog2.clicked.connect(() => {
        actions.open_changelog();
        status_label.label = "● Otworzono changelog";
    });
    grid.attach(btn_changelog2, 2, 0, 1, 1);

    page.append(grid);

    page.append(section_label("Zgłaszanie problemów"));

    var bug_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
        margin_top = 8,
        homogeneous = true
    };

    var btn_bug2 = create_action_card(
        "dialog-warning-symbolic",
        "Zgłoś błąd",
        "GitHub Issues – zgłoś problem lub usterię"
    );
    btn_bug2.clicked.connect(() => {
        actions.report_bug();
        status_label.label = "● Otworzono tracker błędów";
    });
    bug_box.append(btn_bug2);

    var btn_forum2 = create_action_card(
        "internet-group-chat-symbolic",
        "Forum dyskusyjne",
        "GitHub Discussions – zadaj pytanie społeczności"
    );
    btn_forum2.clicked.connect(() => {
        actions.open_forum();
        status_label.label = "● Otworzono forum";
    });
    bug_box.append(btn_forum2);

    var spacer = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    spacer.hexpand = true;
    bug_box.append(spacer);

    page.append(bug_box);

    scroll.set_child(page);
    return scroll;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "O systemie" page
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_about_page(Actions actions, Gtk.Label status_label) {
    var scroll = new Gtk.ScrolledWindow() {
        hscrollbar_policy = Gtk.PolicyType.NEVER,
        vexpand = true,
        hexpand = true
    };

    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        margin_start = 32,
        margin_end = 32,
        margin_top = 28,
        margin_bottom = 28
    };

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 28 };

    var title = new Gtk.Label("O systemie");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);
    page.append(hero_box);

    // System info table
    page.append(section_label("Informacje o systemie"));

    var info_card = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        margin_top = 8,
        margin_bottom = 24
    };
    info_card.add_css_class("motd-card");

    // Vala does not support stacked arrays (string[][]), so we build rows manually.
    string[] row_keys = {
        "Dystrybucja", "Wariant", "Wersja aplikacji", "Jądro", "Architektura", "Licencja"
    };
    string[] row_vals = {
        "HackerOS",
        read_distro_variant(),
        "0.5.0",
        read_kernel_version(),
        get_arch(),
        "GPL-3.0-or-later"
    };

    for (int i = 0; i < row_keys.length; i++) {
        var row_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
            margin_top = 4,
            margin_bottom = 4
        };
        var key = new Gtk.Label(row_keys[i] + ":");
        key.add_css_class("motd-header");
        key.halign = Gtk.Align.START;
        key.width_chars = 22;
        key.xalign = 0;
        var val = new Gtk.Label(row_vals[i]);
        val.add_css_class("motd-text");
        val.halign = Gtk.Align.START;
        row_box.append(key);
        row_box.append(val);
        info_card.append(row_box);
    }
    page.append(info_card);

    page.append(section_label("Linki"));
    var link_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
        margin_top = 8,
        homogeneous = true
    };

    var btn_web = create_action_card(
        "applications-internet-symbolic",
        "Strona HackerOS",
        "hackeros-linux-system.github.io"
    );
    btn_web.clicked.connect(() => {
        actions.open_website();
        status_label.label = "● Otworzono stronę HackerOS";
    });
    link_box.append(btn_web);

    var btn_gh = create_action_card(
        "system-software-install-symbolic",
        "GitHub",
        "Kod źródłowy projektu"
    );
    btn_gh.clicked.connect(() => {
        actions.open_github();
        status_label.label = "● Otworzono GitHub";
    });
    link_box.append(btn_gh);

    var btn_x2 = create_action_card(
        "internet-chat-symbolic",
        "X / Twitter",
        "@hackeros_linux"
    );
    btn_x2.clicked.connect(() => {
        actions.open_x();
        status_label.label = "● Otworzono X";
    });
    link_box.append(btn_x2);

    page.append(link_box);

    scroll.set_child(page);
    return scroll;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: read distro variant
// ─────────────────────────────────────────────────────────────────────────────
private string read_distro_variant() {
    try {
        string rc;
        FileUtils.get_contents("/etc/xdg/kcm-about-distrorc", out rc);
        foreach (string line in rc.split("\n")) {
            if (line.has_prefix("Variant="))
                return line[8:line.length].strip();
        }
    } catch (Error e) {}
    return "Standard";
}

private string read_kernel_version() {
    try {
        string kernel;
        FileUtils.get_contents("/proc/version", out kernel);
        // First token after "Linux version "
        string[] parts = kernel.split(" ");
        if (parts.length >= 3) return parts[2];
    } catch (Error e) {}
    return "Nieznane";
}

private string get_arch() {
    string output;
    try {
        GLib.Process.spawn_command_line_sync("uname -m", out output, null, null);
        return output.strip();
    } catch (Error e) {}
    return "x86_64";
}

// ─────────────────────────────────────────────────────────────────────────────
// Main build_ui – assembles the full application window
// ─────────────────────────────────────────────────────────────────────────────
public void build_ui(Adw.ApplicationWindow window, Actions actions) {

    // ── Header bar ────────────────────────────────────────────────────────────
    var header_bar = new Adw.HeaderBar();
    var win_title = new Adw.WindowTitle("HackerOS Welcome", "v0.5.0");
    header_bar.title_widget = win_title;
    header_bar.show_end_title_buttons = true;

    // ── Status bar at the bottom ──────────────────────────────────────────────
    var status_bar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8) {
        margin_start = 16,
        margin_end = 16,
        margin_top = 6,
        margin_bottom = 6
    };
    status_bar.add_css_class("status-bar");

    var status_dot = new Gtk.Label("●");
    status_dot.add_css_class("status-dot");

    var status_label = new Gtk.Label("Gotowy.");
    status_label.add_css_class("status-text");
    status_label.halign = Gtk.Align.START;
    status_label.hexpand = true;

    // Set status in Actions so old callbacks still work
    actions.subtitle_label = status_label;
    actions.parent_window = window;

    var footer = new Gtk.Label("© 2025 HackerOS Team  •  GPL-3.0");
    footer.add_css_class("footer-label");
    footer.halign = Gtk.Align.END;

    status_bar.append(status_dot);
    status_bar.append(status_label);
    status_bar.append(footer);

    // ── Sidebar ───────────────────────────────────────────────────────────────
    var sidebar = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        width_request = 210
    };
    sidebar.add_css_class("sidebar");

    var nav_home  = create_nav_button("go-home-symbolic", "Strona główna");
    var nav_docs  = create_nav_button("help-contents-symbolic", "Dokumentacja");
    var nav_about = create_nav_button("help-about-symbolic", "O systemie");

    nav_home.add_css_class("active");

    // Section label "NAWIGACJA"
    var nav_section = new Gtk.Label("NAWIGACJA");
    nav_section.add_css_class("sidebar-section-label");
    nav_section.halign = Gtk.Align.START;
    sidebar.append(nav_section);

    sidebar.append(nav_home);
    sidebar.append(nav_docs);
    sidebar.append(nav_about);

    var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
    sep.add_css_class("sidebar-separator");
    sidebar.append(sep);

    var tools_section = new Gtk.Label("NARZĘDZIA");
    tools_section.add_css_class("sidebar-section-label");
    tools_section.halign = Gtk.Align.START;
    sidebar.append(tools_section);

    var nav_software = create_nav_button("system-software-install-symbolic", "Sklep z aplikacjami");
    var nav_update   = create_nav_button("system-software-update-symbolic", "Aktualizacja systemu");
    nav_software.clicked.connect(() => {
        actions.open_software();
        status_label.label = "● Uruchomiono sklep z aplikacjami";
    });
    nav_update.clicked.connect(() => {
        actions.update_system();
        status_label.label = "● Uruchomiono aktualizację…";
    });
    sidebar.append(nav_software);
    sidebar.append(nav_update);

    // Spacer to push version to bottom
    var spacer = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    spacer.vexpand = true;
    sidebar.append(spacer);

    var ver_lbl = new Gtk.Label("HackerOS Welcome 0.5.0");
    ver_lbl.add_css_class("footer-label");
    ver_lbl.margin_bottom = 8;
    ver_lbl.margin_start = 16;
    ver_lbl.halign = Gtk.Align.START;
    sidebar.append(ver_lbl);

    // ── Pages (stack) ─────────────────────────────────────────────────────────
    var stack = new Gtk.Stack() {
        transition_type = Gtk.StackTransitionType.CROSSFADE,
        transition_duration = 150,
        hexpand = true,
        vexpand = true
    };

    var page_home  = build_home_page(actions, status_label);
    var page_docs  = build_docs_page(actions, status_label);
    var page_about = build_about_page(actions, status_label);

    stack.add_named(page_home,  "home");
    stack.add_named(page_docs,  "docs");
    stack.add_named(page_about, "about");
    stack.set_visible_child_name("home");

    // Nav button signals – switch pages and toggle .active class
    nav_home.clicked.connect(() => {
        stack.set_visible_child_name("home");
        nav_home.add_css_class("active");
        nav_docs.remove_css_class("active");
        nav_about.remove_css_class("active");
    });
    nav_docs.clicked.connect(() => {
        stack.set_visible_child_name("docs");
        nav_docs.add_css_class("active");
        nav_home.remove_css_class("active");
        nav_about.remove_css_class("active");
    });
    nav_about.clicked.connect(() => {
        stack.set_visible_child_name("about");
        nav_about.add_css_class("active");
        nav_home.remove_css_class("active");
        nav_docs.remove_css_class("active");
    });

    // ── Layout assembly ───────────────────────────────────────────────────────
    // Sidebar + content split
    var body = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
        vexpand = true,
        hexpand = true
    };
    body.append(sidebar);

    var body_sep = new Gtk.Separator(Gtk.Orientation.VERTICAL);
    body.append(body_sep);

    var content_wrap = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        hexpand = true,
        vexpand = true
    };
    content_wrap.add_css_class("content-area");
    content_wrap.append(stack);
    body.append(content_wrap);

    // Outer vertical layout: header + body + status
    var root = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    root.append(header_bar);
    root.append(body);
    root.append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
    root.append(status_bar);

    window.content = root;
}
