public class DocExporter : Object {

    public static bool export_markdown(GenericArray<DocSection> sections, string path) {
        var sb = new StringBuilder();
        sb.append("# Dokumentacja HackerOS\n\n");
        sb.append("_Wyeksportowano z aplikacji HackerOS Welcome na podstawie danych ze strony HackerOS Website._\n\n");
        sb.append("---\n\n");

        foreach (var s in sections) {
            sb.append("## ").append(s.title).append("\n\n");

            if (!s.available) {
                sb.append("_Ta sekcja nie ma jeszcze opublikowanej treści na stronie HackerOS Website._\n\n");
                continue;
            }

            if (s.lang_used != "pl") {
                string lang_name = (s.lang_used == "en") ? "angielskim" : "niemieckim";
                sb.append("_Treść dostępna tylko w języku ").append(lang_name).append("._\n\n");
            }

            sb.append(s.body).append("\n\n");

            if (s.code_snippets.length > 0) {
                sb.append("**Polecenia:**\n\n");
                foreach (var c in s.code_snippets) {
                    sb.append("```\n").append(c).append("\n```\n\n");
                }
            }
        }

        try {
            FileUtils.set_contents(path, sb.str);
            return true;
        } catch (Error e) {
            return false;
        }
    }

    public static bool export_pdf(GenericArray<DocSection> sections, string path) {
        double page_w = 595.0;  // A4 w punktach
        double page_h = 842.0;
        double margin = 48.0;
        double content_w = page_w - 2 * margin;

        Cairo.PdfSurface surface = new Cairo.PdfSurface(path, page_w, page_h);
        if (surface.status() != Cairo.Status.SUCCESS) return false;
        var cr = new Cairo.Context(surface);

        var title_font = new Pango.FontDescription();
        title_font.set_family("Sans");
        title_font.set_weight(Pango.Weight.BOLD);
        title_font.set_size((int) (20 * Pango.SCALE));

        var heading_font = new Pango.FontDescription();
        heading_font.set_family("Sans");
        heading_font.set_weight(Pango.Weight.BOLD);
        heading_font.set_size((int) (14 * Pango.SCALE));

        var note_font = new Pango.FontDescription();
        note_font.set_family("Sans");
        note_font.set_size((int) (9 * Pango.SCALE));

        var body_font = new Pango.FontDescription();
        body_font.set_family("Sans");
        body_font.set_size((int) (10 * Pango.SCALE));

        double y = margin;

        y = render_paragraph(cr, surface, "Dokumentacja HackerOS", title_font, content_w, margin, y, page_h);
        y += 16;

        foreach (var s in sections) {
            y = render_paragraph(cr, surface, s.title, heading_font, content_w, margin, y, page_h);
            y += 6;

            if (!s.available) {
                y = render_paragraph(cr, surface, "Ta sekcja nie ma jeszcze opublikowanej treści na stronie HackerOS Website.", note_font, content_w, margin, y, page_h);
                y += 16;
                continue;
            }

            if (s.lang_used != "pl") {
                string lang_name = (s.lang_used == "en") ? "angielskim" : "niemieckim";
                y = render_paragraph(cr, surface, "Treść dostępna tylko w języku " + lang_name + ".", note_font, content_w, margin, y, page_h);
                y += 6;
            }

            foreach (var para in s.body.split("\n\n")) {
                if (para.strip() == "") continue;
                y = render_paragraph(cr, surface, para, body_font, content_w, margin, y, page_h);
                y += 8;
            }

            y += 14;
        }

        surface.show_page();
        surface.finish();
        return true;
    }

    /* Rysuje pojedynczy akapit tekstu z zawijaniem wierszy, automatycznie
     * przechodząc na nową stronę PDF, gdy zabraknie miejsca. Zwraca nową
     * pozycję Y (poniżej narysowanego tekstu). */
    private static double render_paragraph(
        Cairo.Context cr, Cairo.PdfSurface surface,
        string text, Pango.FontDescription font,
        double content_w, double margin, double y, double page_h
    ) {
        var layout = Pango.cairo_create_layout(cr);
        layout.set_font_description(font);
        layout.set_width((int) (content_w * Pango.SCALE));
        layout.set_wrap(Pango.WrapMode.WORD_CHAR);
        layout.set_text(text, -1);

        int w, h;
        layout.get_pixel_size(out w, out h);

        if (y + h > page_h - margin) {
            surface.show_page();
            y = margin;
        }

        cr.save();
        cr.move_to(margin, y);
        Pango.cairo_show_layout(cr, layout);
        cr.restore();

        return y + h;
    }
}
