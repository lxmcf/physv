private const int BODY_COUNT = 20;

namespace Physv {
    private Raylib.Color[] colours;
    private Raylib.Color[] outlines;

    private PhysicsWorld world;

    public static int main (string[] args) {
        Raylib.init_window (1280, 768, "Physv test");
        Raylib.set_target_fps (60);

        init_game ();

        while (!Raylib.window_should_close ()) {
            update_game ();

            Raylib.begin_drawing ();
            Raylib.clear_background ({ 50, 60, 70, 255 });
                draw_game ();
            Raylib.end_drawing ();
        }

        Raylib.close_window ();

        return 0;
    }

    public void init_game () {
        colours = new Raylib.Color[BODY_COUNT];
        outlines = new Raylib.Color[BODY_COUNT];

        world = new PhysicsWorld ();

        for (int i = 0; i < BODY_COUNT; i++) {
            int type = Raylib.get_random_value (0, 1);
            float x = Raylib.get_random_value (64, Raylib.get_render_width () - 64);
            float y = Raylib.get_random_value (64, Raylib.get_render_height () - 64);

            if (type == ShapeType.CIRCLE) {
                world.add_body (
                    PhysicsBody.create_circle_body (32.0f, { x, y }, 1.0f, false, 0.5f)
                );
            } else if (type == ShapeType.BOX) {
                world.add_body (
                    PhysicsBody.create_box_body (64.0f, 64.0f, { x, y }, 1.0f, false, 0.5f)
                );
            }

            colours[i] = {
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                255
            };

            outlines[i] = Raylib.WHITE;
        }
    }

    public static void update_game () {
        float direction_x = 0.0f;
        float direction_y = 0.0f;

        float force_magnitude = 200.0f;

        if (Raylib.is_key_down (Raylib.KeyboardKey.LEFT)) direction_x--;
        if (Raylib.is_key_down (Raylib.KeyboardKey.RIGHT)) direction_x++;
        if (Raylib.is_key_down (Raylib.KeyboardKey.UP)) direction_y--;
        if (Raylib.is_key_down (Raylib.KeyboardKey.DOWN)) direction_y++;

        if (direction_x != 0 || direction_y != 0) {
            PhysicsBody body;
            if (world.get_body (0, out body)) {
                Vector2 force_direction = Vector2.normalise ({ direction_x, direction_y });
                Vector2 force = Vector2.multiply_value (force_direction, force_magnitude);

                body.add_force (force);
            }
        }

        world.step (Raylib.get_frame_time ());
        wrap_bodies ();
    }

    public static void draw_game () {
        for (int i = 0; i < world.body_count; i++) {
            PhysicsBody body;

            if (world.get_body (i, out body)) {
                if (body.shape_type == ShapeType.CIRCLE) {
                    Raylib.draw_circle_vector ({ body.position.x, body.position.y }, body.radius, colours[i]);
                    Raylib.draw_circle_sector_lines ({ body.position.x, body.position.y }, body.radius, 0.0f, 360.0f, 26, outlines[i]);
                } else if (body.shape_type == ShapeType.BOX) {
                    draw_polygon_filled (body.get_transformed_vertices (), colours[i]);
                    draw_polygon_outline (body.get_transformed_vertices (), outlines[i]);
                }

                if (i == 0) {
                    Raylib.draw_circle_vector ({ body.position.x, body.position.y }, 8, Raylib.RED);
                }
            }
        }
    }

    public static void draw_polygon_outline (Vector2[] vertices, Raylib.Color color) {
        for (int i = 0; i < vertices.length; i++) {
            Vector2 start = vertices[i];
            Vector2 end = vertices[(i + 1) % vertices.length];

            Raylib.draw_line_vector ({ start.x, start.y }, { end.x, end.y }, color);
        }
    }

    //  NOTE: This is from ChatGPT and very scuffed
    public static void draw_polygon_filled (Vector2[] vertices, Raylib.Color color) {
        Vector2 pivot = vertices[0];

        for (int i = vertices.length - 1; i > 1 ; i--) {
            Raylib.draw_triangle (
                { pivot.x, pivot.y },
                { vertices[i].x, vertices[i].y },
                { vertices[i - 1].x, vertices[i - 1].y },
                color
            );
        }
    }

    public void wrap_bodies () {
        float view_width = Raylib.get_render_width ();
        float view_height = Raylib.get_render_height ();

        for (int i = 0; i < world.body_count; i ++) {
            PhysicsBody body;

            if (world.get_body (i, out body)) {
                if (body.position.x < 0) { body.move_to (Vector2.add (body.position, { view_width, 0.0f })); }
                if (body.position.x > view_width) { body.move_to (Vector2.subtract (body.position, { view_width, 0.0f })); }

                if (body.position.y < 0) { body.move_to (Vector2.add (body.position, { 0.0f, view_height })); }
                if (body.position.y > view_height) { body.move_to (Vector2.subtract (body.position, { 0.0f, view_height })); }
            }
        }
    }
}
