// src/ui.rs
use adw::prelude::*;
use adw::{HeaderBar, ToolbarView};
use gtk::prelude::*;
use gtk::{Align, Box as GtkBox, Button, FlowBox, Image, Label, Orientation, PolicyType, ScrolledWindow, Separator};
use glib::clone;
use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;
use gdk_pixbuf::Pixbuf;
use crate::actions::Actions;

pub fn build_ui(window: &adw::ApplicationWindow, actions: Rc<RefCell<Actions>>) {
    // HeaderBar
    let header_bar = HeaderBar::builder()
        .show_end_title_buttons(true)
        .build();

    // Title widget with logo and title
    let title_box = GtkBox::builder()
        .orientation(Orientation::Horizontal)
        .spacing(10)
        .build();

    // Logo
    let logo_path = "/usr/share/HackerOS/ICONS/Plymouth-Icons/watermark.png";
    let logo_image = if Path::new(logo_path).exists() {
        let pixbuf = Pixbuf::from_file_at_scale(logo_path, 32, 32, true).ok();
        Image::from_pixbuf(pixbuf.as_ref())
    } else {
        Image::new()
    };
    title_box.append(&logo_image);

    // Title label
    let title_label = Label::builder()
        .label("Witaj w HackerOS!")
        .use_markup(true)
        .build();
    title_label.set_markup("<span font='Arial bold 20'>Witaj w HackerOS!</span>");
    title_box.append(&title_label);

    header_bar.set_title_widget(Some(&title_box));

    // Content box
    let content_box = GtkBox::builder()
        .orientation(Orientation::Vertical)
        .spacing(15)
        .margin_top(20)
        .margin_start(20)
        .margin_end(20)
        .margin_bottom(20)
        .build();

    // Subtitle
    let subtitle_label = Label::builder()
        .label("Twój system do Gier i Etycznego Hakowania")
        .use_markup(true)
        .halign(Align::Center)
        .build();
    subtitle_label.set_markup("<span font='Arial 18'>Twój system do Gier i Etycznego Hakowania</span>");
    subtitle_label.style_context().add_class("subtitle");
    content_box.append(&subtitle_label);

    actions.borrow_mut().subtitle_label = Some(subtitle_label.clone());

    // Separator
    let separator = Separator::builder()
        .orientation(Orientation::Horizontal)
        .margin_start(10)
        .margin_end(10)
        .build();
    content_box.append(&separator);

    // ScrolledWindow for buttons
    let scrolled_window = ScrolledWindow::builder()
        .hscrollbar_policy(PolicyType::Never)
        .vscrollbar_policy(PolicyType::Automatic)
        .hexpand(true)
        .vexpand(true)
        .build();
    content_box.append(&scrolled_window);

    // FlowBox for buttons
    let flow_box = FlowBox::builder()
        .column_spacing(15)
        .row_spacing(15)
        .margin_start(10)
        .margin_end(10)
        .margin_bottom(20)
        .homogeneous(true)
        .min_children_per_line(2)
        .max_children_per_line(3)
        .build();
    scrolled_window.set_child(Some(&flow_box));

    // Buttons
    let buttons = vec![
        ("Otwórz stronę HackerOS", clone!(@strong actions => move || actions.borrow().open_website())),
        ("Otwórz X", clone!(@strong actions => move || actions.borrow().open_x())),
        ("Otwórz sklep z aplikacjami", clone!(@strong actions => move || actions.borrow().open_software())),
        ("Changelog", clone!(@strong actions => move || actions.borrow().open_changelog())),
        ("Informacje o systemie", clone!(@strong actions => move || actions.borrow().open_system_info())),
        ("Zgłoś błąd", clone!(@strong actions => move || actions.borrow().report_bug())),
        ("Forum dyskusyjne", clone!(@strong actions => move || actions.borrow().open_forum())),
        ("Zaktualizuj system", clone!(@strong actions => move || actions.borrow().update_system())),
        ("Uruchom HackerOS Games", clone!(@strong actions => move || actions.borrow().run_command_with_feedback("/usr/share/HackerOS/Scripts/Bin/HackerOS-Games.sh"))),
        ("Hacker Launcher", clone!(@strong actions => move || actions.borrow().run_command_with_feedback("/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher"))),
    ];

    for (label, action) in buttons {
        let button = Button::builder()
            .label(label)
            .build();
        button.connect_clicked(move |_| action());
        flow_box.append(&button);
    }

    // Footer
    let footer_label = Label::builder()
        .label("© 2025 HackerOS Team | All rights reserved")
        .halign(Align::Center)
        .build();
    footer_label.style_context().add_class("footer");
    content_box.append(&footer_label);

    // ToolbarView to integrate header and content
    let toolbar_view = ToolbarView::new();
    toolbar_view.add_top_bar(&header_bar);
    toolbar_view.set_content(Some(&content_box));

    // Set window content
    window.set_content(Some(&toolbar_view));
}
