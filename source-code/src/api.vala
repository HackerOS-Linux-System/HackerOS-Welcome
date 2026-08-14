public class Edition : Object {
    public string id;
    public string name;
    public string? img;
    public string? sf;
    public string? mega;
    public string? drive;
    public string? transfer;
    public string? actions;

    public bool has_any_link() {
        return sf != null || mega != null || drive != null || transfer != null || actions != null;
    }
}

/** Pojedynczy wpis w historii wydań (changelog). */
public class ReleaseEntry : Object {
    public string version;
    public string desc;
    public string[] dates;
    public string[] changelog;
}

/** Kategoria dokumentacji (jedna zakładka na stronie dokumentacji). */
public class DocCategory : Object {
    public string key;
    public string title;
}

/** Wynik pobrania jednej sekcji dokumentacji, wraz z metadanymi pochodzenia. */
public class DocSection : Object {
    public string key;
    public string title;
    public string body;
    /** Który wariant językowy faktycznie dostarczył treść: "pl", "en", "de" lub null. */
    public string? lang_used;
    /** Czy treść tej sekcji w ogóle istnieje na stronie (w którymkolwiek języku). */
    public bool available;
    /** Polecenia (`<code>...</code>`) znalezione w tej sekcji — do przycisków „kopiuj”. */
    public string[] code_snippets;
}

/** Pojedynczy obraz w galerii HackerOS. */
public class GalleryImage : Object {
    public string url;
    public string caption;
}

errordomain ApiError {
    HTTP,
    PARSE
}

public class HackerOSApi : Object {
    private const string BASE_URL = "https://hackeros-linux-system.github.io/HackerOS-Website/";

    /* Struktura dokumentacji na stronie — stabilna lista kluczy zakładek
     * używana jako ostatnia linia obrony, gdyby pobranie doc-engine.js
     * się nie powiodło. Nazwy (tytuły) są zawsze pobierane na żywo. */
    private const string[] FALLBACK_TAB_KEYS = {
        "introduction", "hardware", "installation", "firstSteps",
        "environment", "configuration", "troubleshooting", "license",
        "tools", "programming", "editions", "gaming", "gallery"
    };

    private Soup.Session session;
    private CacheStore cache;

    /** Znacznik czasu ostatniego udanego pobrania danych (z sieci albo, gdy offline, z cache). */
    public DateTime? last_fetch_time { get; private set; default = null; }
    /** Pełny URL ostatnio pobranego zasobu (do wyświetlenia w UI jako dowód, że dane są żywe). */
    public string? last_fetch_url { get; private set; default = null; }
    /** Czy ostatnio zwrócone dane pochodzą z pamięci podręcznej (brak połączenia z siecią). */
    public bool last_fetch_was_cached { get; private set; default = false; }

    public HackerOSApi() {
        session = new Soup.Session();
        session.timeout = 15;
        session.user_agent = "HackerOS-Welcome/0.7.0";
        cache = new CacheStore();
    }

    /** Katalog cache offline (do użytku np. przez miniatury galerii). */
    public CacheStore cache_store() {
        return cache;
    }

    /** Buduje pełny adres URL zasobu na stronie HackerOS Website (do wyświetlenia w UI). */
    public string resolve_url(string path) {
        return path.has_prefix("http") ? path : BASE_URL + path;
    }

    // ── Niskopoziomowe pobieranie ───────────────────────────────────────

    /* Każde wywołanie doszywa unikalny parametr `_ts` i wysyła nagłówki
     * Cache-Control/Pragma: no-cache, aby wymusić pobranie świeżej wersji
     * pliku bezpośrednio z serwera GitHub Pages, a nie ze stanu
     * zapamiętanego przez pośredniczące cache (przeglądarkowe/CDN). Dzięki
     * temu dane w aplikacji zawsze odzwierciedlają aktualną zawartość
     * strony HackerOS Website, a nie jakąkolwiek kopię "zaszytą" lokalnie.
     *
     * Gdy sieć jest niedostępna, zamiast zwrócić błąd, próbujemy odczytać
     * ostatnią znaną odpowiedź z cache offline (~/.cache/HackerOS/hackeros-welcome/)
     * i oznaczamy wynik jako `last_fetch_was_cached = true`, żeby UI mogło
     * pokazać wyraźną adnotację "dane z {data}, offline" zamiast pustego
     * ekranu błędu. */
    private async string? fetch_text(string path_or_url) throws ApiError {
        string base_url = resolve_url(path_or_url);
        string sep = base_url.contains("?") ? "&" : "?";
        string url = @"$base_url$(sep)_ts=$(GLib.get_real_time())";

        var msg = new Soup.Message("GET", url);
        if (msg == null) throw new ApiError.HTTP("Nieprawidłowy URL: " + url);
        msg.get_request_headers().append("Cache-Control", "no-cache, no-store, must-revalidate");
        msg.get_request_headers().append("Pragma", "no-cache");

        try {
            GLib.Bytes bytes = yield session.send_and_read_async(msg, GLib.Priority.DEFAULT, null);

            if (msg.get_status() != Soup.Status.OK) {
                throw new ApiError.HTTP(@"HTTP $(msg.get_status()) dla $base_url");
            }

            unowned uint8[] data = bytes.get_data();
            int len = data.length;
            uint8[] buf = new uint8[len + 1];
            Memory.copy(buf, data, len);
            buf[len] = 0;
            string text = (string) buf;

            last_fetch_time = new DateTime.now_local();
            last_fetch_url = base_url;
            last_fetch_was_cached = false;
            cache.save(path_or_url, text);

            return text;
        } catch (Error e) {
            /* Sieć zawiodła — spróbuj z cache offline zanim poddamy się całkowicie. */
            DateTime? saved_at;
            string? cached = cache.load(path_or_url, out saved_at);
            if (cached != null) {
                last_fetch_time = saved_at ?? new DateTime.now_local();
                last_fetch_url = base_url;
                last_fetch_was_cached = true;
                return cached;
            }
            throw new ApiError.HTTP(e.message);
        }
    }

    // ── Edycje / pobieranie ─────────────────────────────────────────────

    public async GenericArray<Edition>? fetch_editions() {
        string? text;
        try {
            text = yield fetch_text("translations/download-editions.js");
        } catch (ApiError e) {
            return null;
        }
        if (text == null) return null;

        var result = new GenericArray<Edition>();
        try {
            var id_re = new Regex("\\bid\\s*:\\s*'([^']*)'");
            MatchInfo mi;
            var starts = new GenericArray<int>();
            if (id_re.match(text, 0, out mi)) {
                do {
                    int s, e;
                    mi.fetch_pos(0, out s, out e);
                    starts.add(s);
                } while (mi.next());
            }
            for (int i = 0; i < starts.length; i++) {
                int start = starts[i];
                int end = (i + 1 < starts.length) ? starts[i + 1] : text.length;
                string block = text[start:end];

                var ed = new Edition();
                ed.id = single_quoted_field(block, "id") ?? "";
                ed.name = single_quoted_field(block, "name") ?? ed.id;
                ed.img = single_quoted_field(block, "img");
                ed.sf = single_quoted_field(block, "sf");
                ed.mega = single_quoted_field(block, "mega");
                ed.drive = single_quoted_field(block, "drive");
                ed.transfer = single_quoted_field(block, "transfer");
                ed.actions = single_quoted_field(block, "actions");
                if (ed.id != "") result.add(ed);
            }
        } catch (Error e) {
            return null;
        }
        return result.length > 0 ? result : null;
    }

    // ── Wydania / changelog ─────────────────────────────────────────────

    public async GenericArray<ReleaseEntry>? fetch_releases() {
        string? text;
        try {
            text = yield fetch_text("translations/files/all/pl.js");
        } catch (ApiError e) {
            return null;
        }
        if (text == null) return null;

        var result = new GenericArray<ReleaseEntry>();
        try {
            var ver_re = new Regex("\\bversion\\s*:\\s*\"");
            MatchInfo mi;
            var starts = new GenericArray<int>();
            if (ver_re.match(text, 0, out mi)) {
                do {
                    int s, e;
                    mi.fetch_pos(0, out s, out e);
                    starts.add(s);
                } while (mi.next());
            }
            for (int i = 0; i < starts.length; i++) {
                int start = starts[i];
                int end = (i + 1 < starts.length) ? starts[i + 1] : text.length;
                string block = text[start:end];

                var rel = new ReleaseEntry();
                rel.version = double_quoted_field(block, "version") ?? "?";
                rel.desc = double_quoted_field(block, "desc") ?? "";
                rel.dates = double_quoted_array(block, "dates");
                rel.changelog = double_quoted_array(block, "changelog");
                result.add(rel);
            }
        } catch (Error e) {
            return null;
        }
        return result.length > 0 ? result : null;
    }

    // ── Dokumentacja ─────────────────────────────────────────────────────

    /*
     * Pobiera CAŁĄ dokumentację (wszystkie kategorie/zakładki) JEDNYM
     * zestawem zapytań sieciowych i zwraca listę gotowych do wyświetlenia
     * sekcji, każda z pełną treścią wyciągniętą z pliku źródłowego strony.
     *
     * Strona HackerOS Website przechowuje treść dokumentacji osobno dla
     * każdego języka (pl, en, de, ...). W praktyce niektóre sekcje
     * (np. "tools", "programming") nie mają jeszcze przetłumaczonej treści
     * po polsku — to prawdziwy brak w danych źródłowych strony, a nie błąd
     * parsera. Dlatego stosujemy kolejność preferencji pl → en → de i
     * jawnie oznaczamy, z którego wariantu językowego pochodzi treść, oraz
     * które sekcje nie mają jeszcze treści w ŻADNYM języku.
     */
    public async GenericArray<DocSection>? fetch_full_documentation() {
        string[] keys = FALLBACK_TAB_KEYS;
        try {
            string? engine_text = yield fetch_text("translations/doc-engine.js");
            if (engine_text != null) {
                string? body = extract_balanced(engine_text, "TAB_KEYS");
                if (body != null) {
                    string[] found = extract_single_quoted(body);
                    if (found.length > 0) keys = found;
                }
            }
        } catch (ApiError e) {
            /* zostajemy przy domyślnej liście kluczy */
        }

        string? doc_text;
        try {
            doc_text = yield fetch_text("translations/hackeros-documentation.js");
        } catch (ApiError e) {
            return null;
        }
        if (doc_text == null) return null;

        string? pl_root = extract_balanced(doc_text, "pl");
        string? en_root = extract_balanced(doc_text, "en");
        string? de_root = extract_balanced(doc_text, "de");

        string? pl_content = (pl_root != null) ? extract_balanced(pl_root, "content") : null;
        string? en_content = (en_root != null) ? extract_balanced(en_root, "content") : null;
        string? de_content = (de_root != null) ? extract_balanced(de_root, "content") : null;

        string[] pl_tabs = {};
        if (pl_root != null) {
            string? tb = extract_bracket(pl_root, "tabs");
            if (tb != null) pl_tabs = extract_single_quoted(tb);
        }

        var result = new GenericArray<DocSection>();

        for (int i = 0; i < keys.length; i++) {
            string key = keys[i];
            var section = new DocSection();
            section.key = key;

            string? title = null;
            string? body = null;
            string? lang = null;
            string[] snippets = {};

            if (pl_content != null) {
                string? tab = extract_balanced(pl_content, key);
                if (tab != null) {
                    string[] vals = extract_any_quoted(tab);
                    if (vals.length > 0) {
                        body = join_body(vals, out title);
                        snippets = extract_code_snippets(vals);
                        lang = "pl";
                    }
                }
            }
            if (body == null && en_content != null) {
                string? tab = extract_balanced(en_content, key);
                if (tab != null) {
                    string[] vals = extract_any_quoted(tab);
                    if (vals.length > 0) {
                        body = join_body(vals, out title);
                        snippets = extract_code_snippets(vals);
                        lang = "en";
                    }
                }
            }
            if (body == null && de_content != null) {
                string? tab = extract_balanced(de_content, key);
                if (tab != null) {
                    string[] vals = extract_any_quoted(tab);
                    if (vals.length > 0) {
                        body = join_body(vals, out title);
                        snippets = extract_code_snippets(vals);
                        lang = "de";
                    }
                }
            }

            if (body != null) {
                section.title = title ?? key;
                section.body = body;
                section.lang_used = lang;
                section.available = true;
                section.code_snippets = snippets;
            } else {
                section.title = (i < pl_tabs.length) ? pl_tabs[i] : key;
                section.body = "";
                section.lang_used = null;
                section.available = false;
                section.code_snippets = {};
            }

            result.add(section);
        }

        return result.length > 0 ? result : null;
    }

    /* Buduje czytelny tekst z listy wyciągniętych łańcuchów: pierwszy
     * łańcuch (zwykle pole "h2") staje się tytułem, reszta — akapitami. */
    private string join_body(string[] vals, out string title) {
        title = html_strip(vals[0]);
        var sb = new StringBuilder();
        for (int i = 1; i < vals.length; i++) {
            string clean = html_strip(vals[i]).strip();
            if (clean == "") continue;
            sb.append(clean);
            sb.append("\n\n");
        }
        return sb.str.strip();
    }

    /* Wyciąga unikalne polecenia z fragmentów `<code>...</code>` znalezionych
     * w surowej (nie-oczyszczonej z HTML) treści sekcji — do przycisków
     * „kopiuj” przy dokumentacji. */
    private string[] extract_code_snippets(string[] raw_vals) {
        var seen = new GenericArray<string>();
        try {
            var re = new Regex("<code>([^<]*)</code>");
            foreach (var v in raw_vals) {
                MatchInfo mi;
                if (re.match(v, 0, out mi)) {
                    do {
                        string raw = mi.fetch(1) ?? "";
                        string clean = raw.replace("&amp;", "&")
                                           .replace("&lt;", "<")
                                           .replace("&gt;", ">")
                                           .replace("&quot;", "\"")
                                           .replace("&#39;", "'")
                                           .replace("&nbsp;", " ")
                                           .strip();
                        if (clean == "") continue;
                        bool dup = false;
                        for (int i = 0; i < seen.length; i++) {
                            if (seen[i] == clean) { dup = true; break; }
                        }
                        if (!dup) seen.add(clean);
                    } while (mi.next());
                }
            }
        } catch (Error e) {}
        return seen.data;
    }

    // ── Galeria ──────────────────────────────────────────────────────────

    /*
     * Sekcja "Galeria" na stronie HackerOS Website jest obecnie placeholderem
     * (patrz DocSection dla klucza "gallery"). Ta metoda próbuje pobrać
     * konwencjonalny manifest `gallery/gallery.json` (tablica obiektów
     * {"src": "...", "caption": "..."}), który HackerOS Team może opublikować
     * w przyszłości. Gdy manifest jeszcze nie istnieje (404) lub ma
     * nieprawidłowy format, zwracamy pustą listę — UI pokazuje wtedy
     * przyjazny placeholder zamiast błędu. */
    public async GenericArray<GalleryImage>? fetch_gallery() {
        string? text;
        try {
            text = yield fetch_text("gallery/gallery.json");
        } catch (ApiError e) {
            return null;
        }
        if (text == null) return null;

        var result = new GenericArray<GalleryImage>();
        try {
            var re = new Regex(
                "\\{\\s*\"src\"\\s*:\\s*\"([^\"]*)\"\\s*(?:,\\s*\"caption\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\")?\\s*\\}"
            );
            MatchInfo mi;
            if (re.match(text, 0, out mi)) {
                do {
                    var img = new GalleryImage();
                    img.url = mi.fetch(1) ?? "";
                    img.caption = unescape_js(mi.fetch(2) ?? "");
                    if (img.url != "") result.add(img);
                } while (mi.next());
            }
        } catch (Error e) {
            return null;
        }
        return result;
    }

    // ── Pomocnicze: parsowanie tekstu JS ────────────────────────────────

    /* Znajduje "key : {" lub "key = {" i zwraca zawartość między parą
     * dopasowanych nawiasów klamrowych (bez klamr), z uwzględnieniem
     * łańcuchów tekstowych (', ") aby nie pogubić się przy '{' wewnątrz
     * treści dokumentacji. */
    private string? extract_balanced(string text, string key) {
        try {
            var re = new Regex("\\b" + Regex.escape_string(key) + "\\s*[:=]\\s*\\{");
            MatchInfo mi;
            if (!re.match(text, 0, out mi)) return null;
            int mstart, mend;
            mi.fetch_pos(0, out mstart, out mend);
            return extract_balanced_from(text, mend - 1);
        } catch (Error e) {
            return null;
        }
    }

    /* Jak extract_balanced, ale dla nawiasów kwadratowych — używane przy
     * tablicach jednopoziomowych typu tabs:[...]. */
    private string? extract_bracket(string text, string key) {
        try {
            var re = new Regex("\\b" + Regex.escape_string(key) + "\\s*:\\s*\\[([^\\]]*)\\]");
            MatchInfo mi;
            if (re.match(text, 0, out mi)) {
                return mi.fetch(1);
            }
        } catch (Error e) {}
        return null;
    }

    private string? extract_balanced_from(string text, int brace_start_byte) {
        unowned uint8[] data = text.data;
        int n = data.length;
        if (brace_start_byte < 0 || brace_start_byte >= n) return null;

        int depth = 0;
        bool in_str = false;
        uint8 quote = 0;
        int body_start = brace_start_byte + 1;

        for (int i = brace_start_byte; i < n; i++) {
            uint8 c = data[i];
            if (in_str) {
                if (c == '\\') { i++; continue; }
                if (c == quote) in_str = false;
                continue;
            }
            if (c == '\'' || c == '"') { in_str = true; quote = c; continue; }
            if (c == '{') { depth++; continue; }
            if (c == '}') {
                depth--;
                if (depth == 0) {
                    int len = i - body_start;
                    if (len < 0) return "";
                    uint8[] slice = data[body_start:i];
                    uint8[] buf = new uint8[slice.length + 1];
                    Memory.copy(buf, slice, slice.length);
                    buf[slice.length] = 0;
                    return (string) buf;
                }
            }
        }
        return null;
    }

    private string? single_quoted_field(string block, string key) {
        try {
            var re = new Regex("\\b" + Regex.escape_string(key) + "\\s*:\\s*'([^']*)'");
            MatchInfo mi;
            if (re.match(block, 0, out mi)) return mi.fetch(1);
        } catch (Error e) {}
        return null;
    }

    private string? double_quoted_field(string block, string key) {
        try {
            var re = new Regex("\\b" + Regex.escape_string(key) + "\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");
            MatchInfo mi;
            if (re.match(block, 0, out mi)) return unescape_js(mi.fetch(1));
        } catch (Error e) {}
        return null;
    }

    private string[] double_quoted_array(string block, string key) {
        try {
            var re = new Regex("\\b" + Regex.escape_string(key) + "\\s*:\\s*\\[([^\\]]*)\\]");
            MatchInfo mi;
            if (re.match(block, 0, out mi)) {
                return extract_double_quoted(mi.fetch(1));
            }
        } catch (Error e) {}
        return {};
    }

    /* Wyciąga wszystkie literały tekstowe niezależnie od stylu cudzysłowu —
     * treść "pl"/"en" na stronie jest zapisana jako literały JS (apostrofy),
     * a "de" jako JSON (cudzysłowy). Dzięki temu jeden mechanizm obsługuje
     * oba warianty formatu spotykane na stronie HackerOS Website. */
    private string[] extract_any_quoted(string text) {
        var results = new GenericArray<string>();
        try {
            var re = new Regex("'((?:\\\\.|[^'\\\\])*)'|\"((?:\\\\.|[^\"\\\\])*)\"");
            MatchInfo mi;
            if (re.match(text, 0, out mi)) {
                do {
                    string? g1 = mi.fetch(1);
                    string? g2 = mi.fetch(2);
                    string raw = (g1 != null) ? g1 : (g2 ?? "");
                    results.add(unescape_js(raw));
                } while (mi.next());
            }
        } catch (Error e) {}
        return results.data;
    }

    private string[] extract_single_quoted(string text) {
        var results = new GenericArray<string>();
        try {
            var re = new Regex("'((?:\\\\.|[^'\\\\])*)'");
            MatchInfo mi;
            if (re.match(text, 0, out mi)) {
                do {
                    results.add(unescape_js(mi.fetch(1)));
                } while (mi.next());
            }
        } catch (Error e) {}
        return results.data;
    }

    private string[] extract_double_quoted(string text) {
        var results = new GenericArray<string>();
        try {
            var re = new Regex("\"((?:\\\\.|[^\"\\\\])*)\"");
            MatchInfo mi;
            if (re.match(text, 0, out mi)) {
                do {
                    results.add(unescape_js(mi.fetch(1)));
                } while (mi.next());
            }
        } catch (Error e) {}
        return results.data;
    }

    private string unescape_js(string s) {
        var sb = new StringBuilder();
        int i = 0;
        unowned uint8[] data = s.data;
        int n = data.length;
        while (i < n) {
            if (data[i] == '\\' && i + 1 < n) {
                uint8 next = data[i + 1];
                if (next == 'u' && i + 5 < n) {
                    var hex = new StringBuilder();
                    for (int k = 0; k < 4; k++) hex.append_c((char) data[i + 2 + k]);
                    uint64 code = uint64.parse("0x" + hex.str);
                    sb.append_unichar((unichar) code);
                    i += 6;
                    continue;
                }
                switch (next) {
                    case 'n': sb.append_c('\n'); break;
                    case 't': sb.append_c('\t'); break;
                    case '\'': sb.append_c('\''); break;
                    case '"': sb.append_c('"'); break;
                    case '\\': sb.append_c('\\'); break;
                    default: sb.append_c((char) next); break;
                }
                i += 2;
            } else {
                sb.append_c((char) data[i]);
                i += 1;
            }
        }
        return sb.str;
    }

    private string html_strip(string s) {
        string result = s;
        try {
            result = new Regex("<[^>]+>").replace(result, -1, 0, " ");
        } catch (Error e) {}
        result = result.replace("&nbsp;", " ")
                        .replace("&amp;", "&")
                        .replace("&lt;", "<")
                        .replace("&gt;", ">")
                        .replace("&quot;", "\"")
                        .replace("&#39;", "'");
        try {
            result = new Regex("[ \\t]{2,}").replace(result, -1, 0, " ");
        } catch (Error e) {}
        return result.strip();
    }
}
