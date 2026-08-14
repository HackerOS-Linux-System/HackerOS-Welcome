private delegate void RetryFunc();

/* Zabezpieczenie defensywne: niektóre teksty w aplikacji pochodzą z
 * dynamicznych źródeł zewnętrznych (wyjście poleceń systemowych, pliki
 * /proc, /etc). Ta funkcja gwarantuje, że trafiający do widgetów GTK/Pango
 * tekst jest zawsze poprawnym UTF-8 — w razie wątpliwości podmienia
 * nieprawidłowe dane na bezpieczną wartość zastępczą zamiast ryzykować
 * ostrzeżenie/błąd renderowania. */
private string sanitize_utf8(string s, string fallback = "?") {
    if (s.validate()) return s;
    return fallback;
}

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
// Helpery: stany ładowania / błędu dla treści pobieranych z API strony
// ─────────────────────────────────────────────────────────────────────────────
private void clear_box(Gtk.Box box) {
    Gtk.Widget? child;
    while ((child = box.get_first_child()) != null) {
        box.remove(child);
    }
}

private void set_loading_box(Gtk.Box slot, string message) {
    clear_box(slot);
    var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    var spinner = new Gtk.Spinner();
    spinner.spinning = true;
    row.append(spinner);
    var lbl = new Gtk.Label(message);
    lbl.add_css_class("footer-label");
    row.append(lbl);
    slot.append(row);
}

private void set_error_box(Gtk.Box slot, string message, owned RetryFunc? retry) {
    clear_box(slot);
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
    box.add_css_class("motd-card");

    var lbl = new Gtk.Label(message);
    lbl.add_css_class("action-desc");
    lbl.halign = Gtk.Align.START;
    lbl.wrap = true;
    box.append(lbl);

    if (retry != null) {
        var btn = new Gtk.Button.with_label("Spróbuj ponownie");
        btn.halign = Gtk.Align.START;
        btn.add_css_class("distro-badge");
        btn.clicked.connect(() => retry());
        box.append(btn);
    }
    slot.append(box);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: "chip" źródła pobierania (SourceForge, Mega, Drive, Transfer, Actions)
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget create_source_chip(string label, string? url, string suggested_name, Actions actions, Gtk.Label status_label) {
    var btn = new Gtk.Button.with_label(label);
    btn.add_css_class("chip-btn");
    if (url == null) {
        btn.sensitive = false;
    } else {
        btn.clicked.connect(() => {
            start_download_flow.begin(btn, url, suggested_name, label, actions, status_label);
        });
    }
    return btn;
}

/*
 * Prawdziwe pobieranie pliku (np. ISO edycji HackerOS) z paskiem postępu,
 * zamiast samego otwierania linku w przeglądarce. Źródła takie jak
 * SourceForge/Mega/Google Drive często są stronami pośredniczącymi
 * (landing page), a nie bezpośrednim plikiem — dlatego najpierw sprawdzamy
 * nagłówek Content-Type; jeśli to HTML, przechodzimy na dotychczasowe
 * zachowanie (otwarcie w przeglądarce) z wyraźnym komunikatem dlaczego.
 */
private async void start_download_flow(Gtk.Widget owner, string url, string suggested_name, string source_label, Actions actions, Gtk.Label status_label) {
    var parent = owner.get_root() as Gtk.Window;
    var dm = new DownloadManager();

    status_label.label = "● Sprawdzanie źródła: " + source_label + "…";
    string? content_type = yield dm.peek_content_type(url);

    if (content_type == null || content_type.has_prefix("text/html")) {
        actions.open_link(url, "Otwarto źródło: " + source_label);
        status_label.label = "● Źródło " + source_label + " wymaga przeglądarki (strona pośrednicząca) — otwarto link.";
        return;
    }

    var file_dialog = new Gtk.FileDialog();
    file_dialog.title = "Zapisz plik z " + source_label;
    file_dialog.initial_name = suggested_name;

    GLib.File? dest = null;
    try {
        dest = yield file_dialog.save(parent, null);
    } catch (Error e) {
        return; // użytkownik anulował wybór miejsca zapisu
    }
    if (dest == null) return;

    var dialog = new Adw.Window() {
        title = "Pobieranie — " + source_label,
        default_width = 440,
        default_height = 170,
        modal = true
    };
    if (parent != null) dialog.transient_for = parent;

    var toolbar_view = new Adw.ToolbarView();
    toolbar_view.add_top_bar(new Adw.HeaderBar());

    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 14) {
        margin_start = 20, margin_end = 20, margin_top = 20, margin_bottom = 20
    };

    var info_lbl = new Gtk.Label(dest.get_basename() ?? suggested_name);
    info_lbl.add_css_class("action-title");
    info_lbl.halign = Gtk.Align.START;
    info_lbl.wrap = true;
    box.append(info_lbl);

    var pbar = new Gtk.ProgressBar() { show_text = true };
    box.append(pbar);

    var cancel_btn = new Gtk.Button.with_label("Anuluj");
    cancel_btn.halign = Gtk.Align.END;
    cancel_btn.add_css_class("distro-badge");
    cancel_btn.clicked.connect(() => dm.cancel());
    box.append(cancel_btn);

    toolbar_view.set_content(box);
    dialog.set_content(toolbar_view);
    dialog.present();

    dm.progress.connect((downloaded, total) => {
        double dl_mb = downloaded / 1048576.0;
        if (total > 0) {
            pbar.fraction = (double) downloaded / (double) total;
            pbar.text = "%.1f MB / %.1f MB".printf(dl_mb, total / 1048576.0);
        } else {
            pbar.pulse();
            pbar.text = "%.1f MB".printf(dl_mb);
        }
    });

    bool success = yield dm.download(url, dest);
    dialog.destroy();

    if (success) {
        status_label.label = "● Pobrano: " + (dest.get_basename() ?? suggested_name);
    } else {
        status_label.label = "● Pobieranie przerwane lub nieudane (" + source_label + ").";
    }
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

    // Row 2 — nowe sekcje: pobieranie edycji oraz wydania
    var btn_download = create_action_card(
        "folder-download-symbolic",
        "Pobierz HackerOS",
        "Wszystkie edycje systemu do pobrania"
    );
    btn_download.clicked.connect(() => {
        actions.open_download();
        status_label.label = "● Otworzono stronę pobierania";
    });
    grid.attach(btn_download, 0, 2, 1, 1);

    var btn_releases = create_action_card(
        "document-properties-symbolic",
        "Wydania",
        "Historia wersji i changelog"
    );
    btn_releases.clicked.connect(() => {
        actions.open_changelog();
        status_label.label = "● Otworzono wydania";
    });
    grid.attach(btn_releases, 1, 2, 1, 1);

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
// Build the "Pobieranie" page — lista edycji HackerOS pobierana live z API
// strony HackerOS Website (translations/download-editions.js).
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_download_page(HackerOSApi api, Actions actions, AppSettings settings, Gtk.Label status_label, out RetryFunc refresh) {
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

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 24 };

    var title = new Gtk.Label("Pobieranie");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);

    var sub = new Gtk.Label("Lista edycji HackerOS pobierana na żywo ze strony hackeros-linux-system.github.io. Wybierz źródło pobierania dla danej edycji.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    sub.wrap = true;
    hero_box.append(sub);
    page.append(hero_box);

    var search = new Gtk.SearchEntry();
    search.placeholder_text = "🔍 Szukaj edycji…";
    search.margin_bottom = 12;
    page.append(search);

    page.append(section_label("Edycje systemu"));

    var source_lbl = new Gtk.Label("");
    source_lbl.add_css_class("footer-label");
    source_lbl.halign = Gtk.Align.START;
    source_lbl.margin_top = 4;
    source_lbl.margin_bottom = 8;
    source_lbl.wrap = true;
    page.append(source_lbl);

    var slot = new Gtk.Box(Gtk.Orientation.VERTICAL, 12) {
        margin_top = 4,
        margin_bottom = 24
    };
    page.append(slot);

    var refresh_btn = new Gtk.Button.with_label("Odśwież listę edycji");
    refresh_btn.add_css_class("distro-badge");
    refresh_btn.halign = Gtk.Align.START;
    refresh_btn.clicked.connect(() => {
        populate_download_slot.begin(slot, source_lbl, search, api, actions, settings, status_label);
    });
    page.append(refresh_btn);

    populate_download_slot.begin(slot, source_lbl, search, api, actions, settings, status_label);

    refresh = () => {
        populate_download_slot.begin(slot, source_lbl, search, api, actions, settings, status_label);
    };

    scroll.set_child(page);
    return scroll;
}

private async void populate_download_slot(Gtk.Box slot, Gtk.Label source_lbl, Gtk.SearchEntry search, HackerOSApi api, Actions actions, AppSettings settings, Gtk.Label status_label) {
    set_loading_box(slot, "Pobieranie listy edycji…");
    source_lbl.label = "";
    var editions = yield api.fetch_editions();
    clear_box(slot);

    if (editions == null) {
        set_error_box(slot, "Nie udało się pobrać listy edycji z HackerOS Website (brak sieci i brak danych w pamięci podręcznej). Sprawdź połączenie z internetem i spróbuj ponownie.", () => {
            populate_download_slot.begin(slot, source_lbl, search, api, actions, settings, status_label);
        });
        status_label.label = "● Błąd pobierania listy edycji";
        return;
    }

    if (api.last_fetch_time != null) {
        if (api.last_fetch_was_cached) {
            source_lbl.label = "⚠ Brak połączenia z internetem — pokazano dane z pamięci podręcznej z "
                + api.last_fetch_time.format("%d.%m.%Y %H:%M") + " (offline)";
        } else {
            source_lbl.label = "● Pobrano na żywo z " + api.resolve_url("translations/download-editions.js")
                + "  •  " + api.last_fetch_time.format("%H:%M:%S");
        }
    }

    var list_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
    slot.append(list_box);

    render_edition_list(list_box, editions, "", actions, settings, status_label);

    search.search_changed.connect(() => {
        render_edition_list(list_box, editions, search.text, actions, settings, status_label);
    });

    status_label.label = "● Pobrano " + editions.length.to_string() + " edycji HackerOS";
}

private void render_edition_list(Gtk.Box list_box, GenericArray<Edition> editions, string query, Actions actions, AppSettings settings, Gtk.Label status_label) {
    clear_box(list_box);
    string q = query.down().strip();
    int shown = 0;
    foreach (var ed in editions) {
        if (q != "" && !(ed.name.down().contains(q) || ed.id.down().contains(q))) continue;
        list_box.append(create_edition_card(ed, actions, settings, status_label));
        shown++;
    }
    if (shown == 0) {
        var empty = new Gtk.Label("Brak edycji pasujących do wyszukiwania „" + query + "”.");
        empty.add_css_class("action-desc");
        empty.halign = Gtk.Align.START;
        empty.wrap = true;
        list_box.append(empty);
    }
}

private Gtk.Widget create_edition_card(Edition ed, Actions actions, AppSettings settings, Gtk.Label status_label) {
    var card = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
    card.add_css_class("motd-card");

    var top = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    var name_lbl = new Gtk.Label(ed.name);
    name_lbl.add_css_class("action-title");
    name_lbl.halign = Gtk.Align.START;
    name_lbl.hexpand = true;
    top.append(name_lbl);

    if (!ed.has_any_link()) {
        var soon = new Gtk.Label("WKRÓTCE");
        soon.add_css_class("distro-badge");
        top.append(soon);
    }
    card.append(top);

    var chips = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8) { margin_top = 2 };
    string suggested = "HackerOS-" + ed.id + ".iso";

    // Kolejność chipów źródeł zgodna z preferencją ustawioną w Ustawieniach.
    foreach (var src in settings.source_order()) {
        switch (src) {
            case "sf":
                chips.append(create_source_chip("SourceForge", ed.sf, suggested, actions, status_label));
                break;
            case "mega":
                chips.append(create_source_chip("Mega", ed.mega, suggested, actions, status_label));
                break;
            case "drive":
                chips.append(create_source_chip("Google Drive", ed.drive, suggested, actions, status_label));
                break;
            case "transfer":
                chips.append(create_source_chip("Transfer.it", ed.transfer, suggested, actions, status_label));
                break;
            case "actions":
                chips.append(create_source_chip("GitHub Actions", ed.actions, suggested, actions, status_label));
                break;
        }
    }
    card.append(chips);

    return card;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "Dokumentacja" page — statyczne skróty + kategorie dokumentacji
// pobierane na żywo z API strony (translations/hackeros-documentation.js
// i translations/doc-engine.js), z podglądem treści bez opuszczania aplikacji.
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_docs_page(HackerOSApi api, Actions actions, Gtk.Label status_label, out RetryFunc refresh) {
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

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 6 };

    var title = new Gtk.Label("Dokumentacja");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);

    var sub = new Gtk.Label("Pełna dokumentacja HackerOS pobierana na żywo ze strony projektu i czytana w całości bezpośrednio w tej aplikacji.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    sub.wrap = true;
    hero_box.append(sub);
    page.append(hero_box);

    var source_lbl = new Gtk.Label("");
    source_lbl.add_css_class("footer-label");
    source_lbl.halign = Gtk.Align.START;
    source_lbl.margin_bottom = 12;
    source_lbl.wrap = true;
    page.append(source_lbl);

    var search = new Gtk.SearchEntry();
    search.placeholder_text = "🔍 Szukaj w kategoriach dokumentacji…";
    search.margin_bottom = 12;
    page.append(search);

    var export_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8) { margin_bottom = 12 };
    var export_md_btn = new Gtk.Button.with_label("Eksportuj jako Markdown");
    export_md_btn.add_css_class("chip-btn");
    var export_pdf_btn = new Gtk.Button.with_label("Eksportuj jako PDF");
    export_pdf_btn.add_css_class("chip-btn");
    export_box.append(export_md_btn);
    export_box.append(export_pdf_btn);
    page.append(export_box);

    var reader_slot = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    page.append(reader_slot);

    var refresh_btn = new Gtk.Button.with_label("Odśwież dokumentację");
    refresh_btn.add_css_class("distro-badge");
    refresh_btn.halign = Gtk.Align.START;
    refresh_btn.margin_bottom = 24;
    refresh_btn.clicked.connect(() => {
        populate_docs_reader.begin(reader_slot, source_lbl, search, export_md_btn, export_pdf_btn, api, actions, status_label);
    });
    page.append(refresh_btn);

    populate_docs_reader.begin(reader_slot, source_lbl, search, export_md_btn, export_pdf_btn, api, actions, status_label);

    refresh = () => {
        populate_docs_reader.begin(reader_slot, source_lbl, search, export_md_btn, export_pdf_btn, api, actions, status_label);
    };

    page.append(build_docs_extra_section(actions, status_label));

    scroll.set_child(page);
    return scroll;
}

/*
 * Pobiera CAŁĄ dokumentację JEDNYM zapytaniem (przez HackerOSApi) i buduje
 * dwupanelowy czytnik osadzony bezpośrednio na stronie: lista kategorii po
 * lewej + treść po prawej. Przełączanie kategorii jest natychmiastowe, bo
 * cała treść jest już w pamięci — bez ponownego łączenia się z siecią i bez
 * opuszczania aplikacji. Lista kategorii jest filtrowana wyszukiwarką, a
 * polecenia (`<code>`) w treści mają przyciski „kopiuj”.
 */
private async void populate_docs_reader(Gtk.Box reader_slot, Gtk.Label source_lbl, Gtk.SearchEntry search, Gtk.Button export_md_btn, Gtk.Button export_pdf_btn, HackerOSApi api, Actions actions, Gtk.Label status_label) {
    set_loading_box(reader_slot, "Pobieranie pełnej dokumentacji ze strony HackerOS Website…");
    source_lbl.label = "";

    var sections = yield api.fetch_full_documentation();
    clear_box(reader_slot);

    if (sections == null) {
        set_error_box(reader_slot, "Nie udało się pobrać dokumentacji z HackerOS Website (brak sieci i brak danych w pamięci podręcznej). Sprawdź połączenie z internetem i spróbuj ponownie.", () => {
            populate_docs_reader.begin(reader_slot, source_lbl, search, export_md_btn, export_pdf_btn, api, actions, status_label);
        });
        status_label.label = "● Błąd pobierania dokumentacji";
        return;
    }

    int available_count = 0;
    foreach (var s in sections) if (s.available) available_count++;

    if (api.last_fetch_time != null) {
        if (api.last_fetch_was_cached) {
            source_lbl.label = "⚠ Brak połączenia z internetem — pokazano dokumentację z pamięci podręcznej z "
                + api.last_fetch_time.format("%d.%m.%Y %H:%M") + " (offline)";
        } else {
            source_lbl.label = "● Pobrano na żywo z " + api.resolve_url("translations/hackeros-documentation.js")
                + "  •  " + api.last_fetch_time.format("%H:%M:%S")
                + "  •  " + available_count.to_string() + "/" + sections.length.to_string() + " kategorii z opublikowaną treścią";
        }
    }

    export_md_btn.clicked.connect(() => {
        export_docs.begin(export_md_btn, sections, "markdown", status_label);
    });
    export_pdf_btn.clicked.connect(() => {
        export_docs.begin(export_pdf_btn, sections, "pdf", status_label);
    });

    var reader = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
        height_request = 480,
        margin_bottom = 20
    };
    reader.add_css_class("motd-card");

    var list_scroll = new Gtk.ScrolledWindow() {
        width_request = 240,
        hscrollbar_policy = Gtk.PolicyType.NEVER,
        vexpand = true
    };
    var listbox = new Gtk.ListBox();
    listbox.add_css_class("doc-list");
    listbox.selection_mode = Gtk.SelectionMode.SINGLE;
    list_scroll.set_child(listbox);

    var content_scroll = new Gtk.ScrolledWindow() {
        hexpand = true,
        vexpand = true
    };
    var body_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8) {
        margin_start = 24,
        margin_end = 24,
        margin_top = 20,
        margin_bottom = 20
    };
    content_scroll.set_child(body_box);

    reader.append(list_scroll);
    reader.append(new Gtk.Separator(Gtk.Orientation.VERTICAL));
    reader.append(content_scroll);

    render_doc_list(listbox, sections, "", body_box);

    search.search_changed.connect(() => {
        render_doc_list(listbox, sections, search.text, body_box);
    });

    reader_slot.append(reader);
    status_label.label = "● Wczytano dokumentację (" + available_count.to_string() + "/" + sections.length.to_string() + " kategorii z treścią)";
}

private void render_doc_list(Gtk.ListBox listbox, GenericArray<DocSection> sections, string query, Gtk.Box body_box) {
    Gtk.Widget? child;
    while ((child = listbox.get_first_child()) != null) listbox.remove(child);

    string q = query.down().strip();
    Gtk.ListBoxRow? first_available_row = null;
    Gtk.ListBoxRow? first_row = null;

    foreach (var s in sections) {
        if (q != "" && !(s.title.down().contains(q) || s.body.down().contains(q))) continue;

        var row = new Gtk.ListBoxRow();
        var row_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 8,
            margin_bottom = 8
        };
        var dot = new Gtk.Label(s.available ? "●" : "○");
        dot.add_css_class(s.available ? "status-dot" : "footer-label");
        row_box.append(dot);

        var lbl = new Gtk.Label(s.title);
        lbl.halign = Gtk.Align.START;
        lbl.hexpand = true;
        lbl.wrap = true;
        lbl.add_css_class(s.available ? "action-title" : "action-desc");
        row_box.append(lbl);

        row.child = row_box;
        row.set_data<DocSection>("section", s);
        listbox.append(row);

        if (first_row == null) first_row = row;
        if (s.available && first_available_row == null) first_available_row = row;
    }

    listbox.row_selected.connect((row) => {
        if (row == null) return;
        var s = row.get_data<DocSection>("section");
        render_doc_section_body(body_box, s);
    });

    if (first_available_row != null) {
        listbox.select_row(first_available_row);
    } else if (first_row != null) {
        listbox.select_row(first_row);
    } else {
        clear_box(body_box);
        var empty = new Gtk.Label("Brak kategorii pasujących do wyszukiwania „" + query + "”.");
        empty.add_css_class("action-desc");
        empty.halign = Gtk.Align.START;
        empty.wrap = true;
        body_box.append(empty);
    }
}

private void render_doc_section_body(Gtk.Box body_box, DocSection s) {
    clear_box(body_box);

    var title_lbl = new Gtk.Label(s.title);
    title_lbl.add_css_class("hero-accent");
    title_lbl.halign = Gtk.Align.START;
    title_lbl.wrap = true;
    body_box.append(title_lbl);

    if (!s.available) {
        var msg = new Gtk.Label("Ta kategoria nie ma jeszcze opublikowanej treści na stronie HackerOS Website — sprawdzono na żywo, w danych źródłowych strony po prostu brak jeszcze tej treści (w żadnym języku). To nie jest błąd aplikacji. Sekcja pojawi się tutaj automatycznie, gdy tylko zostanie opublikowana na stronie.");
        msg.add_css_class("action-desc");
        msg.halign = Gtk.Align.START;
        msg.wrap = true;
        msg.margin_top = 6;
        body_box.append(msg);
        return;
    }

    if (s.lang_used != "pl") {
        string lang_name = (s.lang_used == "en") ? "angielską" : "niemiecką";
        var note = new Gtk.Label("ℹ Ta sekcja nie ma jeszcze polskiego tłumaczenia na stronie HackerOS Website — pokazano dostępną wersję " + lang_name + ".");
        note.add_css_class("footer-label");
        note.halign = Gtk.Align.START;
        note.wrap = true;
        body_box.append(note);
    }

    var body_lbl = new Gtk.Label(s.body);
    body_lbl.add_css_class("motd-text");
    body_lbl.halign = Gtk.Align.START;
    body_lbl.wrap = true;
    body_lbl.selectable = true;
    body_lbl.margin_top = 6;
    body_box.append(body_lbl);

    if (s.code_snippets.length > 0) {
        var ch = new Gtk.Label("POLECENIA W TEJ SEKCJI");
        ch.add_css_class("motd-header");
        ch.halign = Gtk.Align.START;
        ch.margin_top = 10;
        body_box.append(ch);

        foreach (var cmd in s.code_snippets) {
            body_box.append(create_code_row(cmd));
        }
    }
}

/* Wiersz z poleceniem (`<code>`) i przyciskiem „kopiuj” do schowka. */
private Gtk.Widget create_code_row(string command) {
    var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
    row.add_css_class("code-row");

    var code_lbl = new Gtk.Label(command);
    code_lbl.add_css_class("code-text");
    code_lbl.halign = Gtk.Align.START;
    code_lbl.hexpand = true;
    code_lbl.wrap = true;
    code_lbl.selectable = true;
    row.append(code_lbl);

    var copy_btn = new Gtk.Button.with_label("Kopiuj");
    copy_btn.add_css_class("chip-btn");
    copy_btn.valign = Gtk.Align.START;
    copy_btn.clicked.connect(() => {
        copy_btn.get_clipboard().set_text(command);
        copy_btn.label = "Skopiowano ✓";
        GLib.Timeout.add(1500, () => {
            copy_btn.label = "Kopiuj";
            return false;
        });
    });
    row.append(copy_btn);

    return row;
}

/* Eksportuje pobraną dokumentację do Markdown lub PDF, z wyborem miejsca
 * zapisu przez systemowe okno dialogowe. */
private async void export_docs(Gtk.Widget owner, GenericArray<DocSection> sections, string format, Gtk.Label status_label) {
    var parent = owner.get_root() as Gtk.Window;

    var file_dialog = new Gtk.FileDialog();
    file_dialog.title = "Zapisz dokumentację jako " + (format == "pdf" ? "PDF" : "Markdown");
    file_dialog.initial_name = (format == "pdf") ? "dokumentacja-hackeros.pdf" : "dokumentacja-hackeros.md";

    GLib.File? dest = null;
    try {
        dest = yield file_dialog.save(parent, null);
    } catch (Error e) {
        return;
    }
    if (dest == null) return;

    string? path = dest.get_path();
    if (path == null) return;

    bool ok = (format == "pdf")
        ? DocExporter.export_pdf(sections, path)
        : DocExporter.export_markdown(sections, path);

    status_label.label = ok
        ? "● Wyeksportowano dokumentację: " + (dest.get_basename() ?? path)
        : "● Eksport dokumentacji nie powiódł się.";
}

private Gtk.Widget build_docs_extra_section(Actions actions, Gtk.Label status_label) {
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

    box.append(section_label("Wolisz przeglądarkę?"));

    var hint = new Gtk.Label("Czytnik powyżej pokazuje pełną treść dokumentacji lokalnie, bez opuszczania aplikacji. Tutaj znajdziesz też odnośniki do wersji online.");
    hint.add_css_class("action-desc");
    hint.halign = Gtk.Align.START;
    hint.margin_bottom = 8;
    hint.wrap = true;
    box.append(hint);

    var grid = new Gtk.Grid() {
        column_spacing = 12,
        row_spacing = 12,
        column_homogeneous = true,
        margin_top = 8,
        margin_bottom = 24
    };

    var btn_sys_docs = create_action_card(
        "help-contents-symbolic",
        "Pełna dokumentacja online",
        "Otwórz stronę dokumentacji w przeglądarce"
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
        "Changelog online",
        "Pełna historia zmian w przeglądarce"
    );
    btn_changelog2.clicked.connect(() => {
        actions.open_changelog();
        status_label.label = "● Otworzono changelog";
    });
    grid.attach(btn_changelog2, 2, 0, 1, 1);

    box.append(grid);

    box.append(section_label("Zgłaszanie problemów"));

    var bug_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
        margin_top = 8,
        homogeneous = true
    };

    var btn_bug2 = create_action_card(
        "dialog-warning-symbolic",
        "Zgłoś błąd",
        "GitHub Issues – zgłoś problem lub usterkę"
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

    box.append(bug_box);
    return box;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "Wydania" page — historia wersji i changelog pobierane live z API
// strony HackerOS Website (translations/files/all/pl.js).
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_releases_page(HackerOSApi api, AppSettings settings, Gtk.Button? nav_badge_target, Gtk.Label status_label, out RetryFunc refresh) {
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

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 12 };

    var title = new Gtk.Label("Wydania");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);

    var sub = new Gtk.Label("Pełna historia wersji i changelog HackerOS, pobierane na żywo ze strony projektu.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    sub.wrap = true;
    hero_box.append(sub);
    page.append(hero_box);

    var update_note = new Gtk.Label("");
    update_note.add_css_class("update-note");
    update_note.halign = Gtk.Align.START;
    update_note.wrap = true;
    update_note.visible = false;
    update_note.margin_bottom = 12;
    page.append(update_note);

    var search = new Gtk.SearchEntry();
    search.placeholder_text = "🔍 Szukaj wydania (np. numer wersji)…";
    search.margin_bottom = 12;
    page.append(search);

    page.append(section_label("Historia wersji"));

    var source_lbl = new Gtk.Label("");
    source_lbl.add_css_class("footer-label");
    source_lbl.halign = Gtk.Align.START;
    source_lbl.margin_top = 4;
    source_lbl.margin_bottom = 8;
    source_lbl.wrap = true;
    page.append(source_lbl);

    var slot = new Gtk.Box(Gtk.Orientation.VERTICAL, 14) {
        margin_top = 4,
        margin_bottom = 24
    };
    page.append(slot);

    var refresh_btn = new Gtk.Button.with_label("Odśwież listę wydań");
    refresh_btn.add_css_class("distro-badge");
    refresh_btn.halign = Gtk.Align.START;
    refresh_btn.clicked.connect(() => {
        populate_releases_slot.begin(slot, source_lbl, search, update_note, nav_badge_target, api, status_label);
    });
    page.append(refresh_btn);

    populate_releases_slot.begin(slot, source_lbl, search, update_note, nav_badge_target, api, status_label);

    refresh = () => {
        populate_releases_slot.begin(slot, source_lbl, search, update_note, nav_badge_target, api, status_label);
    };

    scroll.set_child(page);
    return scroll;
}

private async void populate_releases_slot(Gtk.Box slot, Gtk.Label source_lbl, Gtk.SearchEntry search, Gtk.Label update_note, Gtk.Button? nav_badge_target, HackerOSApi api, Gtk.Label status_label) {
    set_loading_box(slot, "Pobieranie historii wydań…");
    source_lbl.label = "";
    var releases = yield api.fetch_releases();
    clear_box(slot);

    if (releases == null) {
        set_error_box(slot, "Nie udało się pobrać wydań z HackerOS Website (brak sieci i brak danych w pamięci podręcznej). Sprawdź połączenie z internetem i spróbuj ponownie.", () => {
            populate_releases_slot.begin(slot, source_lbl, search, update_note, nav_badge_target, api, status_label);
        });
        status_label.label = "● Błąd pobierania wydań";
        return;
    }

    if (api.last_fetch_time != null) {
        if (api.last_fetch_was_cached) {
            source_lbl.label = "⚠ Brak połączenia z internetem — pokazano dane z pamięci podręcznej z "
                + api.last_fetch_time.format("%d.%m.%Y %H:%M") + " (offline)";
        } else {
            source_lbl.label = "● Pobrano na żywo z " + api.resolve_url("translations/files/all/pl.js")
                + "  •  " + api.last_fetch_time.format("%H:%M:%S");
        }
    }

    // ── Wykrywanie nowej wersji: porównanie zainstalowanej wersji systemu
    // (z /etc/xdg/kcm-about-distrorc) z najnowszym wpisem w historii wydań. ──
    if (releases.length > 0) {
        string latest_num = extract_version_number(releases[0].version);
        string? installed_full = read_installed_version();
        if (installed_full != null && latest_num != "") {
            string installed_num = extract_version_number(installed_full);
            if (installed_num != "" && compare_version_strings(latest_num, installed_num) > 0) {
                update_note.label = "🆕 Dostępna nowa wersja HackerOS: " + releases[0].version
                    + "  (masz zainstalowaną: " + installed_full + ")";
                update_note.visible = true;
                if (nav_badge_target != null) set_nav_badge(nav_badge_target, true);
            } else if (nav_badge_target != null) {
                set_nav_badge(nav_badge_target, false);
            }
        }
    }

    var list_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 14);
    slot.append(list_box);

    render_release_list(list_box, releases, "");

    search.search_changed.connect(() => {
        render_release_list(list_box, releases, search.text);
    });

    status_label.label = "● Pobrano " + releases.length.to_string() + " wydań";
}

private void render_release_list(Gtk.Box list_box, GenericArray<ReleaseEntry> releases, string query) {
    clear_box(list_box);
    string q = query.down().strip();
    int shown = 0;
    foreach (var rel in releases) {
        if (q != "" && !(rel.version.down().contains(q) || rel.desc.down().contains(q))) continue;
        list_box.append(create_release_card(rel));
        shown++;
    }
    if (shown == 0) {
        var empty = new Gtk.Label("Brak wydań pasujących do wyszukiwania „" + query + "”.");
        empty.add_css_class("action-desc");
        empty.halign = Gtk.Align.START;
        empty.wrap = true;
        list_box.append(empty);
    }
}

private Gtk.Widget create_release_card(ReleaseEntry rel) {
    var card = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    card.add_css_class("motd-card");

    var ver = new Gtk.Label(rel.version);
    ver.add_css_class("hero-accent");
    ver.halign = Gtk.Align.START;
    card.append(ver);

    if (rel.desc != "") {
        var desc = new Gtk.Label(rel.desc);
        desc.add_css_class("hero-subtitle");
        desc.halign = Gtk.Align.START;
        desc.wrap = true;
        card.append(desc);
    }

    if (rel.dates.length > 0) {
        var dh = new Gtk.Label("DATY WYDANIA");
        dh.add_css_class("motd-header");
        dh.halign = Gtk.Align.START;
        dh.margin_top = 8;
        card.append(dh);
        foreach (var d in rel.dates) {
            var l = new Gtk.Label("• " + d);
            l.add_css_class("motd-text");
            l.halign = Gtk.Align.START;
            l.wrap = true;
            card.append(l);
        }
    }

    if (rel.changelog.length > 0) {
        var ch = new Gtk.Label("CO NOWEGO");
        ch.add_css_class("motd-header");
        ch.halign = Gtk.Align.START;
        ch.margin_top = 8;
        card.append(ch);
        foreach (var c in rel.changelog) {
            var l = new Gtk.Label("• " + c);
            l.add_css_class("motd-text");
            l.halign = Gtk.Align.START;
            l.wrap = true;
            card.append(l);
        }
    }

    return card;
}

// ── Wykrywanie nowej wersji: pomocnicze funkcje ─────────────────────────────

private string? read_installed_version() {
    try {
        string rc;
        FileUtils.get_contents("/etc/xdg/kcm-about-distrorc", out rc);
        foreach (string line in rc.split("\n")) {
            if (line.has_prefix("Version=")) {
                string val = line[8:line.length].strip();
                return val.validate() ? val : null;
            }
        }
    } catch (Error e) {}
    return null;
}

private string extract_version_number(string s) {
    try {
        var re = new Regex("[0-9]+(?:\\.[0-9]+)*");
        MatchInfo mi;
        if (re.match(s, 0, out mi)) return mi.fetch(0);
    } catch (Error e) {}
    return "";
}

private int compare_version_strings(string a, string b) {
    string[] pa = a.split(".");
    string[] pb = b.split(".");
    int len = int.max(pa.length, pb.length);
    for (int i = 0; i < len; i++) {
        int va = (i < pa.length) ? int.parse(pa[i]) : 0;
        int vb = (i < pb.length) ? int.parse(pb[i]) : 0;
        if (va != vb) return va - vb;
    }
    return 0;
}

/* Dodaje lub usuwa mały czerwony wskaźnik "nowość" na przycisku nawigacji. */
private void set_nav_badge(Gtk.Button nav_button, bool show) {
    var box = nav_button.child as Gtk.Box;
    if (box == null) return;

    Gtk.Widget? child = box.get_first_child();
    while (child != null) {
        var next = child.get_next_sibling();
        if (child.has_css_class("nav-badge")) box.remove(child);
        child = next;
    }

    if (show) {
        var dot = new Gtk.Label("●");
        dot.add_css_class("nav-badge");
        box.append(dot);
    }
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

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 20 };

    var title = new Gtk.Label("O systemie");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);

    var sub = new Gtk.Label("Bieżący stan systemu HackerOS.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    hero_box.append(sub);
    page.append(hero_box);

    var about_btn = new Gtk.Button.with_label("O programie HackerOS Welcome");
    about_btn.add_css_class("distro-badge");
    about_btn.halign = Gtk.Align.START;
    about_btn.margin_bottom = 20;
    about_btn.clicked.connect(() => {
        show_about_window(about_btn);
    });
    page.append(about_btn);

    // ── Panel "Stan systemu" ─────────────────────────────────────────────────
    page.append(section_label("Stan systemu"));

    var status_slot = new Gtk.Box(Gtk.Orientation.VERTICAL, 12) {
        margin_top = 8,
        margin_bottom = 24
    };
    page.append(status_slot);

    var refresh_status_btn = new Gtk.Button.with_label("Odśwież stan systemu");
    refresh_status_btn.add_css_class("distro-badge");
    refresh_status_btn.halign = Gtk.Align.START;
    refresh_status_btn.margin_bottom = 24;
    refresh_status_btn.clicked.connect(() => {
        populate_system_status.begin(status_slot);
    });
    page.append(refresh_status_btn);

    populate_system_status.begin(status_slot);

    // ── Informacje o dystrybucji ─────────────────────────────────────────────
    page.append(section_label("Informacje o systemie"));

    var info_card = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
        margin_top = 8,
        margin_bottom = 24
    };
    info_card.add_css_class("motd-card");

    string[] row_keys = { "Dystrybucja", "Wariant", "Wersja aplikacji", "Jądro", "Architektura", "Licencja" };
    string[] row_vals = {
        "HackerOS",
        read_distro_variant(),
        "0.7.0",
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

    var btn_web = create_action_card("applications-internet-symbolic", "Strona HackerOS", "hackeros-linux-system.github.io");
    btn_web.clicked.connect(() => {
        actions.open_website();
        status_label.label = "● Otworzono stronę HackerOS";
    });
    link_box.append(btn_web);

    var btn_gh = create_action_card("system-software-install-symbolic", "GitHub", "Kod źródłowy projektu");
    btn_gh.clicked.connect(() => {
        actions.open_github();
        status_label.label = "● Otworzono GitHub";
    });
    link_box.append(btn_gh);

    var btn_x2 = create_action_card("internet-chat-symbolic", "X / Twitter", "@hackeros_linux");
    btn_x2.clicked.connect(() => {
        actions.open_x();
        status_label.label = "● Otworzono X";
    });
    link_box.append(btn_x2);

    page.append(link_box);

    scroll.set_child(page);
    return scroll;
}

/* Zbiera i renderuje panel "Stan systemu": dysk, RAM, aktualizacje apt, uptime. */
private async void populate_system_status(Gtk.Box slot) {
    set_loading_box(slot, "Sprawdzanie stanu systemu (dysk, RAM, aktualizacje apt)…");

    // SystemInfo.collect() wykonuje m.in. `apt list --upgradable`, co może
    // zająć od ułamka sekundy do kilku sekund — uruchamiamy to w osobnym
    // wątku, żeby nie zamrażać interfejsu na czas sprawdzania.
    SystemStatus? status = null;
    SourceFunc callback = populate_system_status.callback;
    new Thread<bool>("hackeros-sysinfo", () => {
        status = SystemInfo.collect();
        Idle.add((owned) callback);
        return true;
    });
    yield;

    clear_box(slot);
    if (status == null) return;

    slot.append(create_status_bar_row("Dysk (/)", status.disk_used + " / " + status.disk_total, status.disk_fraction));
    slot.append(create_status_bar_row("Pamięć RAM", status.ram_used + " / " + status.ram_total, status.ram_fraction));

    var apt_card = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    apt_card.add_css_class("motd-card");
    var apt_icon = new Gtk.Label(status.apt_check_ok ? "📦" : "❔");
    apt_card.append(apt_icon);
    var apt_lbl = new Gtk.Label(
        status.apt_check_ok
            ? (status.apt_upgradable > 0
                ? status.apt_upgradable.to_string() + " dostępnych aktualizacji apt"
                : "System jest aktualny (0 aktualizacji apt)")
            : "Nie udało się sprawdzić aktualizacji apt"
    );
    apt_lbl.add_css_class("action-title");
    apt_lbl.halign = Gtk.Align.START;
    apt_lbl.hexpand = true;
    apt_card.append(apt_lbl);
    slot.append(apt_card);

    var uptime_card = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    uptime_card.add_css_class("motd-card");
    uptime_card.append(new Gtk.Label("⏱"));
    var uptime_lbl = new Gtk.Label("System działa od: " + status.uptime);
    uptime_lbl.add_css_class("action-title");
    uptime_lbl.halign = Gtk.Align.START;
    uptime_lbl.hexpand = true;
    uptime_card.append(uptime_lbl);
    slot.append(uptime_card);
}

private Gtk.Widget create_status_bar_row(string label_text, string value_text, double fraction) {
    var card = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    card.add_css_class("motd-card");

    var top = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
    var lbl = new Gtk.Label(label_text);
    lbl.add_css_class("action-title");
    lbl.halign = Gtk.Align.START;
    lbl.hexpand = true;
    top.append(lbl);

    var val = new Gtk.Label(value_text);
    val.add_css_class("footer-label");
    top.append(val);
    card.append(top);

    var bar = new Gtk.ProgressBar();
    bar.fraction = fraction.clamp(0.0, 1.0);
    card.append(bar);

    return card;
}

/* Natywne okno "O programie" (Adw.AboutWindow) — wersja, licencja, linki,
 * lista współtwórców, zamiast ręcznie sklejanej strony. */
private void show_about_window(Gtk.Widget owner) {
    var parent = owner.get_root() as Gtk.Window;

    var about = new Adw.AboutWindow() {
        application_name = "HackerOS Welcome",
        application_icon = "org.hackeros.welcome",
        developer_name = "HackerOS Team",
        version = "0.7.0",
        comments = "Aplikacja powitalna systemu HackerOS — pobieranie edycji, wydania, dokumentacja i stan systemu w jednym miejscu.",
        website = "https://hackeros-linux-system.github.io/HackerOS-Website/",
        issue_url = "https://github.com/HackerOS-Linux-System/HackerOS-Welcome/issues",
        support_url = "https://github.com/HackerOS-Linux-System/HackerOS-Welcome/discussions",
        license_type = Gtk.License.GPL_3_0,
        copyright = "© 2025 HackerOS Team"
    };
    about.set_developers({ "HackerOS Team https://github.com/HackerOS-Linux-System" });
    about.add_link("Strona HackerOS", "https://hackeros-linux-system.github.io/HackerOS-Website/");
    about.add_link("Repozytorium GitHub", "https://github.com/HackerOS-Linux-System/HackerOS-Welcome");
    if (parent != null) about.transient_for = parent;
    about.present();
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
                return sanitize_utf8(line[8:line.length].strip(), "Standard");
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
        if (parts.length >= 3) return sanitize_utf8(parts[2], "Nieznane");
    } catch (Error e) {}
    return "Nieznane";
}

private string get_arch() {
    string output;
    try {
        GLib.Process.spawn_command_line_sync("uname -m", out output, null, null);
        return sanitize_utf8(output.strip(), "x86_64");
    } catch (Error e) {}
    return "x86_64";
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "Ustawienia" page
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_settings_page(AppSettings settings, Gtk.Label status_label) {
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

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 24 };
    var title = new Gtk.Label("Ustawienia");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);
    var sub = new Gtk.Label("Dostosuj zachowanie aplikacji HackerOS Welcome.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    hero_box.append(sub);
    page.append(hero_box);

    // ── Preferowane źródło pobierania ────────────────────────────────────────
    page.append(section_label("Pobieranie"));
    var source_card = new Gtk.Box(Gtk.Orientation.VERTICAL, 8) { margin_top = 8, margin_bottom = 20 };
    source_card.add_css_class("motd-card");

    var source_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
    var source_row_lbl = new Gtk.Label("Preferowane pierwsze źródło:");
    source_row_lbl.add_css_class("action-title");
    source_row_lbl.halign = Gtk.Align.START;
    source_row_lbl.hexpand = true;
    source_row.append(source_row_lbl);

    string[] source_labels = { "SourceForge", "Mega", "Google Drive", "Transfer.it", "GitHub Actions" };
    string[] source_ids = { "sf", "mega", "drive", "transfer", "actions" };
    var source_dropdown = new Gtk.DropDown.from_strings(source_labels);
    uint current_src_idx = 0;
    for (uint i = 0; i < source_ids.length; i++) if (source_ids[i] == settings.preferred_source) current_src_idx = i;
    source_dropdown.selected = current_src_idx;
    source_dropdown.notify["selected"].connect(() => {
        uint idx = source_dropdown.selected;
        if (idx < source_ids.length) {
            settings.preferred_source = source_ids[idx];
            settings.save();
            status_label.label = "● Ustawiono preferowane źródło: " + source_labels[idx] + " (zmiana widoczna po odświeżeniu strony Pobieranie)";
        }
    });
    source_row.append(source_dropdown);
    source_card.append(source_row);

    var source_hint = new Gtk.Label("Wybrane źródło będzie wyświetlane jako pierwsze na liście każdej edycji do pobrania.");
    source_hint.add_css_class("action-desc");
    source_hint.halign = Gtk.Align.START;
    source_hint.wrap = true;
    source_card.append(source_hint);

    page.append(source_card);

    // ── Kolejność fallbacku językowego dokumentacji ──────────────────────────
    page.append(section_label("Dokumentacja"));
    var lang_card = new Gtk.Box(Gtk.Orientation.VERTICAL, 8) { margin_top = 8, margin_bottom = 20 };
    lang_card.add_css_class("motd-card");

    var lang_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
    var lang_row_lbl = new Gtk.Label("Preferowany język dokumentacji:");
    lang_row_lbl.add_css_class("action-title");
    lang_row_lbl.halign = Gtk.Align.START;
    lang_row_lbl.hexpand = true;
    lang_row.append(lang_row_lbl);

    string[] lang_labels = { "Polski", "English", "Deutsch" };
    string[] lang_ids = { "pl", "en", "de" };
    var lang_dropdown = new Gtk.DropDown.from_strings(lang_labels);
    uint current_lang_idx = 0;
    for (uint i = 0; i < lang_ids.length; i++) if (lang_ids[i] == settings.doc_lang_primary) current_lang_idx = i;
    lang_dropdown.selected = current_lang_idx;
    lang_dropdown.notify["selected"].connect(() => {
        uint idx = lang_dropdown.selected;
        if (idx < lang_ids.length) {
            settings.doc_lang_primary = lang_ids[idx];
            settings.save();
            status_label.label = "● Ustawiono preferowany język dokumentacji: " + lang_labels[idx];
        }
    });
    lang_row.append(lang_dropdown);
    lang_card.append(lang_row);

    var lang_hint = new Gtk.Label("Gdy treść nie jest dostępna w wybranym języku na stronie HackerOS Website, aplikacja automatycznie pokaże najbliższy dostępny język (kolejność zapasowa: pl → en → de).");
    lang_hint.add_css_class("action-desc");
    lang_hint.halign = Gtk.Align.START;
    lang_hint.wrap = true;
    lang_card.append(lang_hint);

    page.append(lang_card);

    // ── Autostart ─────────────────────────────────────────────────────────────
    page.append(section_label("Uruchamianie"));
    var autostart_card = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) { margin_top = 8, margin_bottom = 24 };
    autostart_card.add_css_class("motd-card");

    var autostart_lbl_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4) { hexpand = true };
    var autostart_title = new Gtk.Label("Pokazuj przy starcie systemu");
    autostart_title.add_css_class("action-title");
    autostart_title.halign = Gtk.Align.START;
    autostart_lbl_box.append(autostart_title);
    var autostart_desc = new Gtk.Label("Aplikacja uruchomi się automatycznie po zalogowaniu do systemu.");
    autostart_desc.add_css_class("action-desc");
    autostart_desc.halign = Gtk.Align.START;
    autostart_desc.wrap = true;
    autostart_lbl_box.append(autostart_desc);
    autostart_card.append(autostart_lbl_box);

    var autostart_switch = new Gtk.Switch();
    autostart_switch.valign = Gtk.Align.CENTER;
    autostart_switch.active = settings.is_autostart_active();
    autostart_switch.state_set.connect((state) => {
        bool ok = settings.set_autostart(state);
        status_label.label = ok
            ? (state ? "● Włączono autostart aplikacji" : "● Wyłączono autostart aplikacji")
            : "● Nie udało się zmienić ustawienia autostartu";
        autostart_switch.set_state(ok ? state : !state);
        return true;
    });
    autostart_card.append(autostart_switch);

    page.append(autostart_card);

    scroll.set_child(page);
    return scroll;
}

// ─────────────────────────────────────────────────────────────────────────────
// Build the "Galeria" page — siatka miniatur pobieranych na żywo (gdy strona
// opublikuje manifest gallery/gallery.json), z cache miniatur na dysku.
// ─────────────────────────────────────────────────────────────────────────────
private Gtk.Widget build_gallery_page(HackerOSApi api, Gtk.Label status_label) {
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

    var hero_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) { margin_bottom = 20 };
    var title = new Gtk.Label("Galeria");
    title.add_css_class("hero-title");
    title.halign = Gtk.Align.START;
    hero_box.append(title);
    var sub = new Gtk.Label("Zrzuty ekranu i materiały wizualne HackerOS, sprawdzane na żywo na stronie projektu.");
    sub.add_css_class("hero-subtitle");
    sub.halign = Gtk.Align.START;
    sub.wrap = true;
    hero_box.append(sub);
    page.append(hero_box);

    var gallery_slot = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    page.append(gallery_slot);

    populate_gallery_slot.begin(gallery_slot, api, status_label);

    scroll.set_child(page);
    return scroll;
}

private async void populate_gallery_slot(Gtk.Box slot, HackerOSApi api, Gtk.Label status_label) {
    set_loading_box(slot, "Sprawdzanie galerii na stronie HackerOS Website…");
    var images = yield api.fetch_gallery();
    clear_box(slot);

    if (images == null || images.length == 0) {
        var placeholder = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        placeholder.add_css_class("motd-card");

        var icon = new Gtk.Label("🖼");
        icon.add_css_class("hero-title");
        icon.halign = Gtk.Align.START;
        placeholder.append(icon);

        var msg = new Gtk.Label("Galeria nie została jeszcze opublikowana na stronie HackerOS Website — ta sekcja jest tam obecnie zapowiedzią („wkrótce więcej materiałów”). Gdy tylko HackerOS Team doda zdjęcia, pojawią się tutaj automatycznie, bez potrzeby aktualizacji aplikacji.");
        msg.add_css_class("action-desc");
        msg.wrap = true;
        msg.halign = Gtk.Align.START;
        placeholder.append(msg);

        slot.append(placeholder);
        status_label.label = "● Galeria: brak jeszcze opublikowanych materiałów";
        return;
    }

    var flow = new Gtk.FlowBox();
    flow.selection_mode = Gtk.SelectionMode.NONE;
    flow.max_children_per_line = 4;
    flow.min_children_per_line = 2;
    flow.row_spacing = 12;
    flow.column_spacing = 12;
    slot.append(flow);

    foreach (var img in images) {
        flow.append(create_gallery_tile(img, api));
    }

    status_label.label = "● Wczytano galerię (" + images.length.to_string() + " obrazów)";
}

private Gtk.Widget create_gallery_tile(GalleryImage img, HackerOSApi api) {
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    box.add_css_class("motd-card");
    box.width_request = 200;

    var picture = new Gtk.Picture();
    picture.content_fit = Gtk.ContentFit.COVER;
    picture.height_request = 130;
    box.append(picture);

    if (img.caption != "") {
        var cap = new Gtk.Label(img.caption);
        cap.add_css_class("action-desc");
        cap.wrap = true;
        cap.halign = Gtk.Align.START;
        box.append(cap);
    }

    load_gallery_thumbnail.begin(picture, img.url, api);

    return box;
}

/* Pobiera miniaturę asynchronicznie i przechowuje ją w cache na dysku
 * (~/.cache/HackerOS/hackeros-welcome/gallery/), żeby kolejne wejścia na
 * stronę Galerii nie wymagały ponownego pobierania tych samych obrazów. */
private async void load_gallery_thumbnail(Gtk.Picture picture, string url, HackerOSApi api) {
    string full_url = api.resolve_url(url);
    string thumbs_dir = api.cache_store().subdirectory("gallery");
    string filename = Checksum.compute_for_string(ChecksumType.MD5, full_url);
    string local_path = Path.build_filename(thumbs_dir, filename);

    if (!FileUtils.test(local_path, FileTest.EXISTS)) {
        var dm = new DownloadManager();
        bool ok = yield dm.download(full_url, File.new_for_path(local_path));
        if (!ok) return;
    }

    try {
        var texture = Gdk.Texture.from_filename(local_path);
        picture.set_paintable(texture);
    } catch (Error e) {
        /* Uszkodzona lub nieprawidłowa miniatura — kafelek zostaje pusty. */
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: przełączanie aktywnej strony nawigacji bocznej
// ─────────────────────────────────────────────────────────────────────────────
private void select_nav_page(Gtk.Stack stack, string page_name, Gtk.Button[] all_buttons, Gtk.Button active_button) {
    stack.set_visible_child_name(page_name);
    foreach (var b in all_buttons) {
        if (b == active_button) {
            b.add_css_class("active");
        } else {
            b.remove_css_class("active");
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main build_ui – assembles the full application window
// ─────────────────────────────────────────────────────────────────────────────
public void build_ui(Adw.ApplicationWindow window, Actions actions, HackerOSApi api, AppSettings settings) {

    // ── Header bar ────────────────────────────────────────────────────────────
    var header_bar = new Adw.HeaderBar();
    var win_title = new Adw.WindowTitle("HackerOS Welcome", "v0.7.0");
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

    var nav_home     = create_nav_button("go-home-symbolic", "Strona główna");
    var nav_download = create_nav_button("folder-download-symbolic", "Pobieranie");
    var nav_docs     = create_nav_button("help-contents-symbolic", "Dokumentacja");
    var nav_releases = create_nav_button("document-properties-symbolic", "Wydania");
    var nav_gallery  = create_nav_button("image-x-generic-symbolic", "Galeria");
    var nav_about    = create_nav_button("help-about-symbolic", "O systemie");
    var nav_settings = create_nav_button("preferences-system-symbolic", "Ustawienia");

    Gtk.Button[] nav_buttons = { nav_home, nav_download, nav_docs, nav_releases, nav_gallery, nav_about, nav_settings };

    // Section label "NAWIGACJA"
    var nav_section = new Gtk.Label("NAWIGACJA");
    nav_section.add_css_class("sidebar-section-label");
    nav_section.halign = Gtk.Align.START;
    sidebar.append(nav_section);

    sidebar.append(nav_home);
    sidebar.append(nav_download);
    sidebar.append(nav_docs);
    sidebar.append(nav_releases);
    sidebar.append(nav_gallery);
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
    sidebar.append(nav_settings);

    // Spacer to push version to bottom
    var spacer = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    spacer.vexpand = true;
    sidebar.append(spacer);

    var ver_lbl = new Gtk.Label("HackerOS Welcome 0.7.0");
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
        vexpand = true,
        hhomogeneous = false,
        vhomogeneous = false
    };

    RetryFunc refresh_download;
    RetryFunc refresh_docs;
    RetryFunc refresh_releases;

    var page_home     = build_home_page(actions, status_label);
    var page_download = build_download_page(api, actions, settings, status_label, out refresh_download);
    var page_docs     = build_docs_page(api, actions, status_label, out refresh_docs);
    var page_releases = build_releases_page(api, settings, nav_releases, status_label, out refresh_releases);
    var page_gallery  = build_gallery_page(api, status_label);
    var page_about    = build_about_page(actions, status_label);
    var page_settings = build_settings_page(settings, status_label);

    stack.add_named(page_home,     "home");
    stack.add_named(page_download, "download");
    stack.add_named(page_docs,     "docs");
    stack.add_named(page_releases, "releases");
    stack.add_named(page_gallery,  "gallery");
    stack.add_named(page_about,    "about");
    stack.add_named(page_settings, "settings");

    // ── Zapamiętywanie ostatnio otwartej zakładki między uruchomieniami ────────
    string[] valid_tabs = { "home", "download", "docs", "releases", "gallery", "about", "settings" };
    string last_tab = settings.load_last_tab("home");
    bool last_tab_valid = false;
    foreach (var t in valid_tabs) if (t == last_tab) last_tab_valid = true;
    if (!last_tab_valid) last_tab = "home";

    stack.set_visible_child_name(last_tab);
    foreach (var b in nav_buttons) b.remove_css_class("active");
    switch (last_tab) {
        case "home": nav_home.add_css_class("active"); break;
        case "download": nav_download.add_css_class("active"); break;
        case "docs": nav_docs.add_css_class("active"); break;
        case "releases": nav_releases.add_css_class("active"); break;
        case "gallery": nav_gallery.add_css_class("active"); break;
        case "about": nav_about.add_css_class("active"); break;
        case "settings": nav_settings.add_css_class("active"); break;
    }

    // Nav button signals – switch pages, toggle .active class, i zapisz stan.
    nav_home.clicked.connect(() => { select_nav_page(stack, "home", nav_buttons, nav_home); settings.save_last_tab("home"); });
    nav_download.clicked.connect(() => { select_nav_page(stack, "download", nav_buttons, nav_download); settings.save_last_tab("download"); });
    nav_docs.clicked.connect(() => { select_nav_page(stack, "docs", nav_buttons, nav_docs); settings.save_last_tab("docs"); });
    nav_releases.clicked.connect(() => { select_nav_page(stack, "releases", nav_buttons, nav_releases); settings.save_last_tab("releases"); });
    nav_gallery.clicked.connect(() => { select_nav_page(stack, "gallery", nav_buttons, nav_gallery); settings.save_last_tab("gallery"); });
    nav_about.clicked.connect(() => { select_nav_page(stack, "about", nav_buttons, nav_about); settings.save_last_tab("about"); });
    nav_settings.clicked.connect(() => { select_nav_page(stack, "settings", nav_buttons, nav_settings); settings.save_last_tab("settings"); });

    // ── Odświeżanie w tle: co godzinę ponawiamy pobranie edycji, wydań i
    // dokumentacji, żeby dane w aplikacji nie starzały się bez potrzeby
    // ręcznego klikania "Odśwież". ──────────────────────────────────────────
    GLib.Timeout.add_seconds(3600, () => {
        refresh_download();
        refresh_docs();
        refresh_releases();
        return true; // powtarzaj co godzinę
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
