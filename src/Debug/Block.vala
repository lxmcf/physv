namespace Physv.Debug {
    public enum TimeMeasure {
        MICROSECONDS = 1000000,
        MILLISECONDS = 1000,
        SECONDS = 1;
    }

    public delegate void AnonymousBlock ();

    public inline static string BLOCK_TIMER (string id, TimeMeasure time_measure, AnonymousBlock block) {
        GLib.Timer timer = new GLib.Timer ();
        double elapsed_time;

        timer.reset ();
        timer.start ();

        block ();

        timer.stop ();
        elapsed_time = timer.elapsed ();

        return "%.3f".printf (elapsed_time * time_measure);
    }
}
