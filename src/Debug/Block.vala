namespace Physv.Debug {
    public enum TimeMeasure {
        MICROSECONDS = 1000000,
        MILLISECONDS = 1000,
        SECONDS = 1;

        public inline string to_string () {
            switch (this) {
                case MICROSECONDS: return "microseconds";
                case MILLISECONDS: return "millisecods";
                case SECONDS: return "seconds";

                default: return "";
            }
        }
    }

    public delegate void AnonymousBlock ();

    private static GLib.Timer? _timer;
    private static double _elapsed_time;

    public inline static void BLOCK_TIMER (string id, TimeMeasure time_measure, AnonymousBlock block, out string? time = null) {
        if (_timer == null) _timer = new GLib.Timer ();

        _timer.reset ();
        _timer.start ();

        block ();

        _timer.stop ();
        _elapsed_time = _timer.elapsed ();

        string output_text = "Timer [%s] took %.3f %s!\n";

        if (time == null) {
            print (output_text, id.up (), _elapsed_time * time_measure, time_measure.to_string ());
        } else {
            time = output_text.printf (id.up (), _elapsed_time * time_measure, time_measure.to_string ());
        }
    }
}
