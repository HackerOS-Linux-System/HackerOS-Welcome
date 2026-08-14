public class DownloadManager : Object {
    /** Emitowany po każdym pobranym fragmencie danych. total może być -1, gdy serwer nie podał rozmiaru. */
    public signal void progress(int64 downloaded, int64 total);
    public signal void finished(bool success, string? error_message);

    private Soup.Session session;
    private Cancellable cancellable;

    public DownloadManager() {
        session = new Soup.Session();
        session.timeout = 0; // pliki ISO mogą być duże — brak sztywnego limitu czasu
        session.user_agent = "HackerOS-Welcome/0.7.0";
        cancellable = new Cancellable();
    }

    public void cancel() {
        cancellable.cancel();
    }

    /* Wykonuje lekkie zapytanie GET tylko po to, by odczytać nagłówek
     * Content-Type, po czym natychmiast zamyka połączenie bez pobierania
     * treści. Używane do rozróżnienia bezpośredniego pliku (np. .iso) od
     * strony pośredniczącej (np. landing page SourceForge/Mega/Drive),
     * której nie da się pobrać strumieniowo i trzeba otworzyć w przeglądarce. */
    public async string? peek_content_type(string url) {
        try {
            var msg = new Soup.Message("GET", url);
            var input_stream = yield session.send_async(msg, GLib.Priority.DEFAULT, null);
            GLib.HashTable<string, string> ct_params;
            string? ct = msg.get_response_headers().get_content_type(out ct_params);
            try {
                yield input_stream.close_async(GLib.Priority.DEFAULT, null);
            } catch (Error e) {}
            return ct;
        } catch (Error e) {
            return null;
        }
    }

    public async bool download(string url, GLib.File dest) {
        GLib.FileOutputStream? out_stream = null;
        try {
            var msg = new Soup.Message("GET", url);
            var input_stream = yield session.send_async(msg, GLib.Priority.DEFAULT, cancellable);

            if (msg.get_status() != Soup.Status.OK) {
                finished(false, @"Serwer zwrócił błąd HTTP $(msg.get_status())");
                return false;
            }

            int64 total = msg.get_response_headers().get_content_length();
            int64 downloaded = 0;

            out_stream = yield dest.replace_async(
                null, false, FileCreateFlags.REPLACE_DESTINATION, GLib.Priority.DEFAULT, cancellable
            );

            size_t chunk_size = 262144; // 256 KB
            while (true) {
                GLib.Bytes bytes = yield input_stream.read_bytes_async(chunk_size, GLib.Priority.DEFAULT, cancellable);
                if (bytes.get_size() == 0) break;
                yield out_stream.write_bytes_async(bytes, GLib.Priority.DEFAULT, cancellable);
                downloaded += bytes.get_size();
                progress(downloaded, total);
            }

            yield out_stream.close_async(GLib.Priority.DEFAULT, null);
            finished(true, null);
            return true;
        } catch (IOError.CANCELLED e) {
            finished(false, "Pobieranie anulowane.");
            return false;
        } catch (Error e) {
            finished(false, e.message);
            return false;
        }
    }
}
