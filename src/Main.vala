private const int BODY_COUNT = 10;

namespace Physv {
    private List<PhysicsBody> body_list;
    private Raylib.Color[] colours;

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
        body_list = new List<PhysicsBody> ();
        colours = new Raylib.Color[BODY_COUNT];

        for (int i = 0; i < BODY_COUNT; i++) {
            //  int type = Raylib.get_random_value (0, 1);
            int type = ShapeType.BOX;

            float x = Raylib.get_random_value (64, Raylib.get_render_width () - 64);
            float y = Raylib.get_random_value (64, Raylib.get_render_height () - 64);

            if (type == ShapeType.CIRCLE) {
                body_list.append (
                    PhysicsBody.create_circle_body (32.0f, { x, y }, 2.0f, false, 0.5f)
                );
            } else if (type == ShapeType.BOX) {
                body_list.append (
                    PhysicsBody.create_box_body (64.0f, 64.0f, { x, y }, 2.0f, false, 0.5f)
                );
            } else {
                warning ("WRONG NUMBER");
            }

            colours[i] = {
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                255
            };
        }
    }

    public static void update_game () {
        float direction_x = 0.0f;
        float direction_y = 0.0f;

        float speed = 120.0f;

        if (Raylib.is_key_down (Raylib.KeyboardKey.LEFT)) direction_x--;
        if (Raylib.is_key_down (Raylib.KeyboardKey.RIGHT)) direction_x++;
        if (Raylib.is_key_down (Raylib.KeyboardKey.UP)) direction_y--;
        if (Raylib.is_key_down (Raylib.KeyboardKey.DOWN)) direction_y++;

        if (direction_x != 0 || direction_y != 0) {
            Vector2 direction = Vector2.normalise ({ direction_x, direction_y });
            Vector2 velocity = Vector2.multiply_value (direction, speed * Raylib.get_frame_time ());

            PhysicsBody body = body_list.nth_data (0);

            body.move (velocity);
        }

        Vector2 normal;
        float depth;

        for (int i = 0; i < body_list.length (); i++) {
            PhysicsBody body = body_list.nth_data (i);
            body.rotate (((float)Math.PI / 2.0f) * Raylib.get_frame_time ());
        }

        #if false
        for (int i = 0; i < body_list.length () - 1; i++) {
            PhysicsBody body1 = body_list.nth_data (i);

            for (int j = i + 1; j < body_list.length (); j++) {
                PhysicsBody body2 = body_list.nth_data (j);

                if (intersec_circles (body1.position, body1.radius, body2.position, body2.radius, out normal, out depth)) {
                    body1.move (Vector2.multiply_value ({ -normal.x, -normal.y }, depth / 2));
                    body2.move (Vector2.multiply_value ({ normal.x, normal.y }, depth / 2));
                }
            }
        }
        #endif
    }

    public static void draw_game () {
        for (int i = 0; i < body_list.length (); i++) {
            PhysicsBody body = body_list.nth_data (i);

            if (body.shape_type == ShapeType.CIRCLE) {
                Raylib.draw_circle_vector ({ body.position.x, body.position.y }, body.radius, colours[i]);
                Raylib.draw_circle_sector_lines ({ body.position.x, body.position.y }, body.radius, 0.0f, 360.0f, 26, Raylib.WHITE);
            } else if (body.shape_type == ShapeType.BOX) {
                draw_polygon_outline (body.get_transformed_vertices (), Raylib.WHITE);
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
}
