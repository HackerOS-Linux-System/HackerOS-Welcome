use adw::prelude::*;
use adw::ApplicationWindow;
use gtk::{Box as GtkBox, Button, Label, Orientation, ScrolledWindow, Separator};
use std::rc::Rc;
use std::cell::RefCell;

use crate::actions::Actions;

pub fn build_ui(window: &ApplicationWindow, actions_rc: Rc<RefCell<Actions>>) {
    let main_box = GtkBox::builder()
    .orientation(Orientation::Vertical)
    .spacing(20)
    .margin_start(20)
    .margin_end(20)
    .margin_top(20)
    .margin_bottom(20)
    .build();

    // Title
    let title_label = Label::builder()
    .label("Witaj w HackerOS!")
    .css_classes(vec!["title".to_string()])
    .build();
    main_box.append(&title_label);

    // Subtitle (feedback label)
    let subtitle_label = Label::builder()
    .label("Wybierz akcję poniżej.")
    .css_classes(vec!["subtitle".to_string()])
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
    .spacing(10)
    .margin_start(10)
    .margin_end(10)
    .margin_top(10)
    .margin_bottom(10)
    .build();

    // Buttons
    let website_button = Button::builder()
    .label("Otwórz stronę HackerOS")
    .build();
    website_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_website()
    });
    buttons_box.append(&website_button);

    let x_button = Button::builder()
    .label("Otwórz X (Twitter)")
    .build();
    x_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_x()
    });
    buttons_box.append(&x_button);

    let software_button = Button::builder()
    .label("Otwórz Sklep z aplikacjami")
    .build();
    software_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_software()
    });
    buttons_box.append(&software_button);

    let changelog_button = Button::builder()
    .label("Otwórz Changelog")
    .build();
    changelog_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_changelog()
    });
    buttons_box.append(&changelog_button);

    let system_info_button = Button::builder()
    .label("Otwórz Informacje o systemie")
    .build();
    system_info_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_system_info()
    });
    buttons_box.append(&system_info_button);

    let report_bug_button = Button::builder()
    .label("Zgłoś błąd")
    .build();
    report_bug_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().report_bug()
    });
    buttons_box.append(&report_bug_button);

    let forum_button = Button::builder()
    .label("Otwórz Forum dyskusyjne")
    .build();
    forum_button.connect_clicked({
        let actions_rc = actions_rc.clone();
        move |_| actions_rc.borrow().open_forum()
    });
    buttons_box.append(&forum_button);

    let update_button = Button::builder()
    .label("Aktualizuj system")
    .build();
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
    .build();
    main_box.append(&footer_label);

    window.set_content(Some(&main_box));
}
