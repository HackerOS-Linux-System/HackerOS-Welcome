public class MotdLoader : Object {
    private const string MOTD_DIR      = "/usr/lib/HackerOS/motd";
    private const string TEMPLATE_PATH = "/usr/lib/HackerOS/motd/template/HackerOS.md";
    private const string DISTRORC_PATH = "/etc/xdg/kcm-about-distrorc";

    /* Load and return the assembled MOTD string.
     * Returns null when the MOTD infrastructure is not installed. */
    public static string? load() {
        // 1. Pick a random tip file
        string? tip_content = pick_random_tip();
        if (tip_content == null) return null;

        // 2. Load template
        string template_text;
        try {
            FileUtils.get_contents(TEMPLATE_PATH, out template_text);
        } catch (Error e) {
            // No template → fall back to just the tip
            template_text = "%TIP%";
        }

        // 3. Substitute %VARIANT%
        string variant = read_variant();
        string assembled = template_text.replace("%VARIANT%", variant);

        // 4. Substitute %TIP%
        assembled = assembled.replace("%TIP%", tip_content);

        // 5. Replace literal '~' with newline (mirrors bash `tr '~' '\n'`)
        assembled = assembled.replace("~", "\n");

        // 6. Strip Markdown syntax so the label shows clean plain text
        assembled = strip_markdown(assembled);

        return assembled;
    }

    /* Strip the most common Markdown syntax so the text looks clean in a
     * plain GTK label.  We handle:
     *   - ATX headings          # Foo  →  Foo
     *   - Bold/italic           **x**, *x*, __x__, _x_  →  x
     *   - Inline code           `x`  →  x
     *   - Fenced code blocks    ```…```  → (removed)
     *   - Table rows            | a | b |  → (removed)
     *   - Table separators      |---|---|  → (removed)
     *   - Bullet list markers   - item, * item  →  • item
     *   - Horizontal rules      ---  →  (removed)
     *   - Leading/trailing whitespace cleaned up
     */
    private static string strip_markdown(string input) {
        string[] lines = input.split("\n");
        var out_lines = new GenericArray<string>();
        bool in_code_block = false;

        foreach (string raw_line in lines) {
            string line = raw_line;

            // Toggle fenced code block – skip lines inside ```
            if (line.strip().has_prefix("```")) {
                in_code_block = !in_code_block;
                continue;
            }
            if (in_code_block) continue;

            // Table rows and separators (contain | characters)
            if (line.strip().has_prefix("|")) continue;

            // Horizontal rules: ---, ***, ___
            var hr_re = /^[\s]*[-\*_]{3,}[\s]*$/;
            if (hr_re.match(line, 0, null)) continue;

            // ATX headings: remove leading # symbols
            var heading_re = /^#{1,6}\s+/;
            line = heading_re.replace(line, -1, 0, "");

            // Bold+italic: ***x*** or ___x___
            var bold_italic_re = /\*{3}([^\*]+)\*{3}/;
            line = bold_italic_re.replace(line, -1, 0, "\\1");
            var bold_italic_re2 = /_{3}([^_]+)_{3}/;
            line = bold_italic_re2.replace(line, -1, 0, "\\1");

            // Bold: **x** or __x__
            var bold_re = /\*{2}([^\*]+)\*{2}/;
            line = bold_re.replace(line, -1, 0, "\\1");
            var bold_re2 = /_{2}([^_]+)_{2}/;
            line = bold_re2.replace(line, -1, 0, "\\1");

            // Italic: *x* or _x_
            var italic_re = /\*([^\*]+)\*/;
            line = italic_re.replace(line, -1, 0, "\\1");
            var italic_re2 = /_([^_]+)_/;
            line = italic_re2.replace(line, -1, 0, "\\1");

            // Inline code: `x`
            var code_re = /`([^`]+)`/;
            line = code_re.replace(line, -1, 0, "\\1");

            // Bullet list markers: "- " or "* " at start of line → "• "
            var bullet_re = /^(\s*)[-\*]\s+/;
            line = bullet_re.replace(line, -1, 0, "\\1• ");

            out_lines.add(line);
        }

        // Join, collapse 3+ consecutive blank lines into 2, trim
        string joined = string.joinv("\n", out_lines.data);
        var multi_blank = /\n{3,}/;
        joined = multi_blank.replace(joined, -1, 0, "\n\n");
        return joined.strip();
    }

    // ── private helpers ──────────────────────────────────────────────────────

    private static string? pick_random_tip() {
        var tip_files = new GenericArray<string>();
        try {
            var dir = Dir.open(MOTD_DIR, 0);
            string? name;
            while ((name = dir.read_name()) != null) {
                if (!name.has_suffix(".md")) continue;
                tip_files.add(Path.build_filename(MOTD_DIR, name));
            }
        } catch (Error e) {
            return null;
        }

        if (tip_files.length == 0) return null;

        int idx = Random.int_range(0, (int32)tip_files.length);
        string chosen = tip_files[idx];

        string content;
        try {
            FileUtils.get_contents(chosen, out content);
        } catch (Error e) {
            return null;
        }
        return content;
    }

    private static string read_variant() {
        try {
            string rc_content;
            FileUtils.get_contents(DISTRORC_PATH, out rc_content);
            foreach (string line in rc_content.split("\n")) {
                if (line.has_prefix("Variant=")) {
                    return line[8:line.length].strip();
                }
            }
        } catch (Error e) { /* ignore */ }
        return "Standard";
    }
}
