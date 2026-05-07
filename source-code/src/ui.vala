private Gtk.Button create_button_with_icon(string label_text, string icon_name) {
    var button = new Gtk.Button();
    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
    var icon = new Gtk.Image.from_icon_name(icon_name) {
        pixel_size = 24 // Set icon size for better look
    };
    hbox.append(icon);
    var label = new Gtk.Label(label_text);
    hbox.append(label);
    button.child = hbox;
    button.halign = Gtk.Align.CENTER; // Center buttons
    return button;
}

public void build_ui(Adw.ApplicationWindow window, Actions actions) {
    // Add HeaderBar for prettier title and standard controls (close, minimize, maximize/fullscreen)
    var header_bar = new Adw.HeaderBar();
    var window_title = new Adw.WindowTitle("Witaj w HackerOS!", "");
    header_bar.title_widget = window_title;
    header_bar.show_end_title_buttons = true; // Ensure window controls (close, etc.)

    var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 20) {
        margin_start = 20,
        margin_end = 20,
        margin_top = 20,
        margin_bottom = 20
    };

    // Prepend the header_bar to main_box for CSD
    main_box.prepend(header_bar);

    // Subtitle (feedback label) below header
    const string[] subtitle_classes = { "subtitle" };
    var subtitle_label = new Gtk.Label("Wybierz akcję poniżej.") {
        css_classes = subtitle_classes,
        halign = Gtk.Align.CENTER
    };
    main_box.append(subtitle_label);

    // Set subtitle_label and parent_window in Actions
    actions.subtitle_label = subtitle_label;
    actions.parent_window = window;

    // Separator
    var separator1 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
    main_box.append(separator1);

    // Scrolled content for buttons
    var scrolled_window = new Gtk.ScrolledWindow() {
        vexpand = true
    };
    var buttons_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 15) { // Increased spacing for prettier look
        margin_start = 10,
        margin_end = 10,
        margin_top = 10,
        margin_bottom = 10,
        halign = Gtk.Align.CENTER // Center the buttons box
    };

    // Buttons with icons for prettier UI
    var website_button = create_button_with_icon("Otwórz stronę HackerOS", "applications-internet-symbolic");
    website_button.clicked.connect(() => actions.open_website());
    buttons_box.append(website_button);

    var x_button = create_button_with_icon("Otwórz X (Twitter)", "internet-chat-symbolic");
    x_button.clicked.connect(() => actions.open_x());
    buttons_box.append(x_button);

    var software_button = create_button_with_icon("Otwórz Sklep z aplikacjami", "system-software-install-symbolic");
    software_button.clicked.connect(() => actions.open_software());
    buttons_box.append(software_button);

    var changelog_button = create_button_with_icon("Otwórz Changelog", "document-properties-symbolic");
    changelog_button.clicked.connect(() => actions.open_changelog());
    buttons_box.append(changelog_button);

    var system_info_button = create_button_with_icon("Otwórz Informacje o systemie", "help-about-symbolic");
    system_info_button.clicked.connect(() => actions.open_system_info());
    buttons_box.append(system_info_button);

    var report_bug_button = create_button_with_icon("Zgłoś błąd", "dialog-warning-symbolic");
    report_bug_button.clicked.connect(() => actions.report_bug());
    buttons_box.append(report_bug_button);

    var forum_button = create_button_with_icon("Otwórz Forum dyskusyjne", "internet-group-chat-symbolic");
    forum_button.clicked.connect(() => actions.open_forum());
    buttons_box.append(forum_button);

    var update_button = create_button_with_icon("Aktualizuj system", "system-software-update-symbolic");
    update_button.clicked.connect(() => actions.update_system());
    buttons_box.append(update_button);

    scrolled_window.set_child(buttons_box);
    main_box.append(scrolled_window);

    // Separator
    var separator2 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
    main_box.append(separator2);

    // Footer
    const string[] footer_classes = { "footer" };
    var footer_label = new Gtk.Label("© 2025 HackerOS Team") {
        css_classes = footer_classes,
        halign = Gtk.Align.CENTER
    };
    main_box.append(footer_label);

    // Use Clamp for responsive/prettier content limiting
    var clamp = new Adw.Clamp() {
        maximum_size = 800, // Limit max width for better centering on large windows
        tightening_threshold = 600
    };
    clamp.child = main_box;

    window.content = clamp;
}
