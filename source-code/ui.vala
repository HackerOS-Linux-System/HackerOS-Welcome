use adw::prelude::*;
use adw::{ApplicationWindow, Clamp, HeaderBar, WindowTitle};
use gtk::{Box as GtkBox, Button, Image, Label, Orientation, ScrolledWindow, Separator};
use std::rc::Rc;
use std::cell::RefCell;

use crate::actions::Actions;

fn create_button_with_icon(label_text: &str, icon_name: &str) -> Button {
    let button = Button::new();
    let hbox = GtkBox::new(Orientation::Horizontal, 6);
    let icon = Image::builder()
    .icon_name(icon_name)
    .pixel_size(24)  // Set icon size for better look
    .build();
    hbox.append(&icon);
    let label = Label::new(Some(label_text));
    hbox.append(&label);
    button.set_child(Some(&hbox));
    button.set_halign(gtk::Align::Center);  // Center buttons
    button
}

pub fn build_ui(window: &ApplicationWindow, actions_rc: Rc<RefCell<Actions>>) {
    // Add HeaderBar for prettier title and standard controls (close, minimize, maximize/fullscreen)
    let header_bar = HeaderBar::new();
    let window_title = WindowTitle::builder()
    .title("Witaj w HackerOS!")
    .subtitle("")
    .build();
    header_bar.set_title_widget(Some(&window_title));
    header_bar.set_show_end_title_buttons(true);  // Ensure window controls (close, etc.)

    let main_box = GtkBox::builder()
    .orientation(Orientation::Vertical)
    .spacing(20)
    .margin_start(20)
    .margin_end(20)
    .margin_top(20)
    .margin_bottom(20)
    .build();

    // Prepend the header_bar to main_box for CSD
    main_box.prepend(&header_bar);

    // Subtitle (feedback label) below header
    let subtitle_label = Label::builder()
    .label("Wybierz akcję poniżej.")
    .css_classes(vec!["subtitle".to_string()])
    .halign(gtk::Align::Center)
    .build();
    main_box.append(&subtitle_label);

    // Set subtitle_label in Actions
    {
        let mut actions = actions_rc.borrow_mut();
        actions.subtitle_label = Some(subtitle_label);
    }

    // Separator
    let separator1 = Separator::new(Orientation::Horizontal);
    main_box.append(&separator1);

    // Scrolled content for buttons
    let scrolled_window = ScrolledWindow::builder()
    .vexpand(true)
    .build();

    let buttons_box = GtkBox::builder()
    .orientation(Orientation::Vertical)
    .spacing(15)  // Increased spacing for prettier look
    .margin_start(10)
    .margin_end(10)
    .margin_top(10)
    .margin_bottom(10)
    .halign(gtk::Align::Center)  // Center the buttons box
    .build();

    // Buttons with icons for prettier UI
    let website_button = create_button_with_icon("Otwórz stronę HackerOS", "applications-internet-symbolic");
    website_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_website()
    });
    buttons_box.append(&website_button);

    let x_button = create_button_with_icon("Otwórz X (Twitter)", "internet-chat-symbolic");
    x_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_x()
    });
    buttons_box.append(&x_button);

    let software_button = create_button_with_icon("Otwórz Sklep z aplikacjami", "system-software-install-symbolic");
    software_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_software()
    });
    buttons_box.append(&software_button);

    let changelog_button = create_button_with_icon("Otwórz Changelog", "document-properties-symbolic");
    changelog_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_changelog()
    });
    buttons_box.append(&changelog_button);

    let system_info_button = create_button_with_icon("Otwórz Informacje o systemie", "help-about-symbolic");
    system_info_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_system_info()
    });
    buttons_box.append(&system_info_button);

    let report_bug_button = create_button_with_icon("Zgłoś błąd", "dialog-warning-symbolic");
    report_bug_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().report_bug()
    });
    buttons_box.append(&report_bug_button);

    let forum_button = create_button_with_icon("Otwórz Forum dyskusyjne", "internet-group-chat-symbolic");
    forum_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_forum()
    });
    buttons_box.append(&forum_button);

    let update_button = create_button_with_icon("Aktualizuj system", "system-software-update-symbolic");
    update_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().update_system()
    });
    buttons_box.append(&update_button);

    scrolled_window.set_child(Some(&buttons_box));
    main_box.append(&scrolled_window);

    // Separator
    let separator2 = Separator::new(Orientation::Horizontal);
    main_box.append(&separator2);

    // Footer
    let footer_label = Label::builder()
    .label("© 2025 HackerOS Team")
    .css_classes(vec!["footer".to_string()])
    .halign(gtk::Align::Center)
    .build();
    main_box.append(&footer_label);

    // Use Clamp for responsive/prettier content limiting
    let clamp = Clamp::builder()
    .maximum_size(800)  // Limit max width for better centering on large windows
    .tightening_threshold(600)
    .build();
    clamp.set_child(Some(&main_box));

    window.set_content(Some(&clamp));
}
