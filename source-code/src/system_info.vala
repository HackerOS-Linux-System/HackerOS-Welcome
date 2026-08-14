public class SystemStatus : Object {
    public string disk_used;
    public string disk_total;
    public double disk_fraction;

    public string ram_used;
    public string ram_total;
    public double ram_fraction;

    public int apt_upgradable;
    public bool apt_check_ok;

    public string uptime;
}

public class SystemInfo : Object {

    public static SystemStatus collect() {
        var status = new SystemStatus();
        collect_disk(status);
        collect_ram(status);
        collect_apt(status);
        collect_uptime(status);
        return status;
    }

    // ── Dysk (/ – system plików root) ───────────────────────────────────

    private static void collect_disk(SystemStatus status) {
        status.disk_used = "?";
        status.disk_total = "?";
        status.disk_fraction = 0.0;
        try {
            var file = File.new_for_path("/");
            var info = file.query_filesystem_info("filesystem::size,filesystem::free");
            uint64 total = info.get_attribute_uint64(FileAttribute.FILESYSTEM_SIZE);
            uint64 free = info.get_attribute_uint64(FileAttribute.FILESYSTEM_FREE);
            uint64 used = (total > free) ? total - free : 0;
            status.disk_used = format_bytes(used);
            status.disk_total = format_bytes(total);
            status.disk_fraction = (total > 0) ? ((double) used / (double) total) : 0.0;
        } catch (Error e) {
            /* Brak dostępu do informacji o systemie plików — pomijamy. */
        }
    }

    // ── RAM (/proc/meminfo) ─────────────────────────────────────────────

    private static void collect_ram(SystemStatus status) {
        status.ram_used = "?";
        status.ram_total = "?";
        status.ram_fraction = 0.0;
        try {
            string contents;
            FileUtils.get_contents("/proc/meminfo", out contents);

            uint64 mem_total = 0, mem_available = 0;
            foreach (string line in contents.split("\n")) {
                if (line.has_prefix("MemTotal:")) {
                    mem_total = parse_meminfo_kb(line);
                } else if (line.has_prefix("MemAvailable:")) {
                    mem_available = parse_meminfo_kb(line);
                }
            }

            if (mem_total > 0) {
                uint64 used_kb = (mem_total > mem_available) ? mem_total - mem_available : 0;
                status.ram_used = format_bytes(used_kb * 1024);
                status.ram_total = format_bytes(mem_total * 1024);
                status.ram_fraction = (double) used_kb / (double) mem_total;
            }
        } catch (Error e) {
            /* /proc/meminfo niedostępne (np. inny system) — pomijamy. */
        }
    }

    private static uint64 parse_meminfo_kb(string line) {
        // Format: "MemTotal:       16384000 kB"
        string[] parts = line.split(":");
        if (parts.length < 2) return 0;
        string rest = parts[1].strip();
        string[] tokens = rest.split(" ");
        if (tokens.length < 1) return 0;
        return uint64.parse(tokens[0]);
    }

    // ── Aktualizacje apt ─────────────────────────────────────────────────

    private static void collect_apt(SystemStatus status) {
        status.apt_upgradable = 0;
        status.apt_check_ok = false;
        try {
            string output, stderr_out;
            int exit_status;
            GLib.Process.spawn_command_line_sync(
                "apt list --upgradable",
                out output,
                out stderr_out,
                out exit_status
            );
            int count = 0;
            foreach (string line in output.split("\n")) {
                string l = line.strip();
                if (l == "") continue;
                if (l.has_prefix("Listing...")) continue;
                count++;
            }
            status.apt_upgradable = count;
            status.apt_check_ok = true;
        } catch (SpawnError e) {
            status.apt_check_ok = false;
        }
    }

    // ── Uptime (/proc/uptime) ───────────────────────────────────────────

    private static void collect_uptime(SystemStatus status) {
        status.uptime = "Nieznany";
        try {
            string contents;
            FileUtils.get_contents("/proc/uptime", out contents);
            string[] parts = contents.strip().split(" ");
            if (parts.length < 1) return;
            double seconds = double.parse(parts[0]);
            status.uptime = format_duration(seconds);
        } catch (Error e) {
            /* /proc/uptime niedostępne — pomijamy. */
        }
    }

    // ── Formatowanie ─────────────────────────────────────────────────────

    private static string format_bytes(uint64 bytes) {
        double gb = (double) bytes / (1024.0 * 1024.0 * 1024.0);
        if (gb >= 1.0) {
            return "%.1f GB".printf(gb);
        }
        double mb = (double) bytes / (1024.0 * 1024.0);
        return "%.0f MB".printf(mb);
    }

    private static string format_duration(double seconds) {
        int days = (int) (seconds / 86400);
        int hours = (int) ((seconds % 86400) / 3600);
        int minutes = (int) ((seconds % 3600) / 60);

        if (days > 0) {
            return @"$(days) d $(hours) godz.";
        } else if (hours > 0) {
            return @"$(hours) godz. $(minutes) min";
        } else {
            return @"$(minutes) min";
        }
    }
}
