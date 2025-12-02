use adw::prelude::*;
use adw::{Application, ApplicationWindow, StyleManager};
use gtk::{CssProvider, gdk::Display};
use std::cell::RefCell;
use std::env;
use std::rc::Rc;

mod actions;
mod ui;

use actions::Actions;
use ui::build_ui;

fn main() {
    let application = Application::builder()
    .application_id("org.hackeros.welcome")
    .build();

    application.connect_startup(|_| {
        StyleManager::default().set_color_scheme(adw::ColorScheme::ForceDark);
    });

    application.connect_activate(|app| {
        let window = ApplicationWindow::builder()
        .application(app)
        .title("HackerOS Welcome")
        .default_width(1000)
        .default_height(750)
        .decorated(false)  // Use false for client-side decorations (CSD) with custom header bar
        .build();

        // Load CSS with improvements for prettier look
        let provider = CssProvider::new();
        provider.load_from_data("
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
    color: #FFFFFF;  /* For symbolic icons */
    }
    ");

        gtk::style_context_add_provider_for_display(
            &Display::default().expect("Error initializing GTK CSS provider."),
                                                    &provider,
                                                    gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );

        let actions = Rc::new(RefCell::new(Actions::new()));
        build_ui(&window, actions.clone());

        window.present();
    });

    application.run_with_args(&env::args().collect::<Vec<_>>());
}
