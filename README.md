# HackerOS Welcome

<div align="center">

![HackerOS Welcome](source-code/images/hackeros-welcome.png)

**Aplikacja powitalna systemu HackerOS**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version](https://img.shields.io/badge/version-0.5.0-green.svg)](https://github.com/HackerOS-Linux-System)
[![GTK4](https://img.shields.io/badge/GTK-4-blue.svg)](https://gtk.org/)
[![libadwaita](https://img.shields.io/badge/libadwaita-≥1.5-orange.svg)](https://gnome.pages.gitlab.gnome.org/libadwaita/)

</div>

---

## O aplikacji

**HackerOS Welcome** to aplikacja powitalna systemu HackerOS. Wyświetla się po pierwszym uruchomieniu systemu i zapewnia szybki dostęp do najważniejszych zasobów: dokumentacji, sklepu z aplikacjami, aktualizacji systemu oraz społeczności.

Aplikacja jest napisana w języku **Vala** i korzysta z **GTK4** oraz **libadwaita**.

### Funkcje

- 🏠 **Strona główna** – hero z nazwą systemu, wariantem dystrybucji i szybkimi akcjami
- 📰 **MOTD (Message of the Day)** – losowa wiadomość dnia pobierana z `/usr/lib/HackerOS/motd/`, identyczna logika jak skrypt bash `motd.sh`
- 📚 **Dokumentacja** – otwiera dokumentację HackerOS oraz dokumentację narzędzi w przeglądarce (Vivaldi lub domyślna)
- 🛒 **Sklep z aplikacjami** – uruchamia GNOME Software
- 🔄 **Aktualizacja systemu** – uruchamia `hacker update` w terminalu (alacritty / konsole / xterm)
- 🐛 **Zgłaszanie błędów** – kieruje na GitHub Issues
- 💬 **Forum dyskusyjne** – kieruje na GitHub Discussions
- ℹ️ **O systemie** – wyświetla informacje o dystrybucji, jądrze i architekturze

### Nawigacja

Aplikacja posiada boczny pasek nawigacyjny (sidebar) z trzema zakładkami:

| Zakładka | Opis |
|---|---|
| **Strona główna** | MOTD + siatka szybkich akcji + sekcja społeczności |
| **Dokumentacja** | Linki do dokumentacji systemu i narzędzi |
| **O systemie** | Informacje o systemie i linki do projektu |

---

## Zrzuty ekranu

> Aplikacja używa wymuszonego ciemnego motywu (`FORCE_DARK`) z zielonym akcentem `#00ff88` inspirowanym estetyką hakerską/terminalową.

---

## Wymagania

### Zależności runtime

| Pakiet | Minimalna wersja |
|---|---|
| `gtk4` | ≥ 4.0 |
| `libadwaita` | ≥ 1.5 |
| `glib-2.0` | ≥ 2.70 |
| `alacritty` / `konsole` / `xterm` | dowolna (terminal do aktualizacji) |
| `gnome-software` | dowolna (sklep z aplikacjami) |
| `vivaldi` / `xdg-open` | dowolna (przeglądarka do dokumentacji) |

### Zależności build

| Narzędzie | Wersja |
|---|---|
| `meson` | ≥ 0.59.0 |
| `ninja` | dowolna |
| `valac` | ≥ 0.54 |
| `gcc` / `clang` | dowolna |
| `pkg-config` | dowolna |

---

## Instalacja

### Z źródeł

```bash
git clone https://github.com/HackerOS-Linux-System/HackerOS-Welcome.git
cd HackerOS-Welcome
meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
```

### Uruchomienie bez instalacji

```bash
meson setup build
ninja -C build
./build/hackeros-welcome
```

---

## Struktura projektu

```
HackerOS-Welcome/
├── meson.build                   # System budowania
├── README.md                     # Ten plik
├── LICENSE                       # Licencja GPL-3.0
├── src/
│   ├── main.vala                 # Klasa aplikacji, CSS, punkt wejścia
│   ├── ui.vala                   # Budowanie interfejsu użytkownika
│   ├── actions.vala              # Handlery akcji (otwieranie URL, terminala itd.)
│   └── motd.vala                 # Ładowanie MOTD z /usr/lib/HackerOS/motd/
├── data/
│   └── org.hackeros.welcome.desktop  # Plik .desktop
└── images/
    └── hackeros-welcome.png      # Ikona aplikacji
```

---

## MOTD – Wiadomość dnia

Aplikacja replikuje logikę skryptu `/usr/lib/HackerOS/motd/motd.sh`:

1. Losuje plik `*.md` z katalogu `/usr/lib/HackerOS/motd/`
2. Wczytuje szablon z `/usr/lib/HackerOS/motd/template/HackerOS.md`
3. Podstawia `%VARIANT%` wariantem dystrybucji z `/etc/xdg/kcm-about-distrorc`
4. Podstawia `%TIP%` zawartością wylosowanego pliku
5. Zamienia znaki `~` na nowe linie (odpowiednik `tr '~' '\n'`)
6. Wyświetla wynikowy tekst w karcie MOTD na stronie głównej

Jeśli katalog MOTD nie istnieje (np. środowisko deweloperskie), karta MOTD jest po prostu ukryta.

---

## Licencja

```
HackerOS Welcome
Copyright (C) 2025 HackerOS Team

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```

Pełny tekst licencji: [`LICENSE`](LICENSE)

---

## Wkład w projekt

1. Zrób fork repozytorium
2. Utwórz gałąź dla swojej funkcji (`git checkout -b feature/moja-funkcja`)
3. Zatwierdź zmiany (`git commit -m 'Dodaj moją funkcję'`)
4. Wypchnij gałąź (`git push origin feature/moja-funkcja`)
5. Otwórz Pull Request

Błędy i sugestje zgłaszaj przez [GitHub Issues](https://github.com/HackerOS-Linux-System/HackerOS-Website/issues).

---

<div align="center">

© 2025 HackerOS Team • GPL-3.0-or-later

</div>
