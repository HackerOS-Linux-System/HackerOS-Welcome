public class CacheStore : Object {
    private string cache_dir;

    public CacheStore() {
        cache_dir = Path.build_filename(
            Environment.get_home_dir(), ".cache", "HackerOS", "hackeros-welcome"
        );
        DirUtils.create_with_parents(cache_dir, 0755);
    }

    private string key_to_path(string key) {
        string safe = key.replace("/", "_").replace("?", "_").replace(":", "_").replace("&", "_");
        return Path.build_filename(cache_dir, safe);
    }

    /** Zapisuje surową treść pod danym kluczem (zwykle: ścieżka zasobu na stronie). */
    public void save(string key, string content) {
        try {
            FileUtils.set_contents(key_to_path(key), content);
        } catch (Error e) {
            /* Brak miejsca na dysku lub brak uprawnień — cache jest tylko
             * usprawnieniem, więc cicho ignorujemy błąd zapisu. */
        }
    }

    /** Odczytuje wcześniej zapisaną treść wraz z datą jej zapisania (mtime pliku). */
    public string? load(string key, out DateTime? saved_at) {
        saved_at = null;
        string path = key_to_path(key);
        if (!FileUtils.test(path, FileTest.EXISTS)) return null;

        string contents;
        try {
            FileUtils.get_contents(path, out contents);
        } catch (Error e) {
            return null;
        }

        try {
            var file = File.new_for_path(path);
            var info = file.query_info(FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
            saved_at = info.get_modification_date_time();
        } catch (Error e) {
            saved_at = null;
        }

        return contents;
    }

    /** Zwraca katalog cache (do przechowywania np. miniatur galerii). */
    public string directory() {
        return cache_dir;
    }

    /** Podkatalog cache dla danego celu (np. "gallery"), tworzony w razie potrzeby. */
    public string subdirectory(string name) {
        string dir = Path.build_filename(cache_dir, name);
        DirUtils.create_with_parents(dir, 0755);
        return dir;
    }
}
