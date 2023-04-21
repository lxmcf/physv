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

    public inline static string BLOCK_TIMER (string id, TimeMeasure time_measure, AnonymousBlock block) {
        GLib.Timer timer = new GLib.Timer ();
        double elapsed_time;

        timer.reset ();
        timer.start ();

        block ();

        timer.stop ();
        elapsed_time = timer.elapsed ();

        string output_text = "Timer [%s] took %.3f %s!\n";

        print (output_text, id.up (), elapsed_time * time_measure, time_measure.to_string ());

        return "%.3f".printf (elapsed_time * time_measure);
    }
}
