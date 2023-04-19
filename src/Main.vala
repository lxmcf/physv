using Physv.Debug;

namespace Physv {
    private List<Raylib.Color?> colours;
    private List<Raylib.Color?> outlines;

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
        colours = new List<Raylib.Color?> ();
        outlines = new List<Raylib.Color?> ();

        colours.append (Raylib.DARKGRAY);
        outlines.append (Raylib.WHITE);

        world = new PhysicsWorld ();

        world.add_body (
            PhysicsBody.create_box_body (1024.0f, 96.0f, { 640.0f, 640.0f }, 1.0f, true, 0.5f)
        );
    }

    public static void update_game () {
        //  float direction_x = 0.0f;
        //  float direction_y = 0.0f;

        //  float force_magnitude = 150.0f;

        //  if (Raylib.is_key_down (Raylib.KeyboardKey.LEFT)) direction_x--;
        //  if (Raylib.is_key_down (Raylib.KeyboardKey.RIGHT)) direction_x++;
        //  if (Raylib.is_key_down (Raylib.KeyboardKey.UP)) direction_y--;
        //  if (Raylib.is_key_down (Raylib.KeyboardKey.DOWN)) direction_y++;

        //  if (direction_x != 0 || direction_y != 0) {
        //      PhysicsBody body;
        //      if (world.get_body (0, out body)) {
        //          Vector2 force_direction = Vector2.normalise ({ direction_x, direction_y });
        //          Vector2 force = Vector2.multiply_value (force_direction, force_magnitude);

        //          body.add_force (force);
        //      }
        //  }

        if (Raylib.is_mouse_button_pressed (Raylib.MouseButton.LEFT)) {
            float width = Raylib.get_random_value (24, 64);
            float height = Raylib.get_random_value (24, 64);

            Raylib.Vector2 mouse = Raylib.get_mouse_position ();

            world.add_body (
                PhysicsBody.create_box_body (width, height, { mouse.x, mouse.y } , 1.0f, false, 0.5f)
            );

            colours.append ({
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                255
            });

            outlines.append (Raylib.WHITE);
        }

        if (Raylib.is_mouse_button_pressed (Raylib.MouseButton.RIGHT)) {
            float radius = Raylib.get_random_value (16, 32);

            Raylib.Vector2 mouse = Raylib.get_mouse_position ();

            world.add_body (
                PhysicsBody.create_circle_body (radius, { mouse.x, mouse.y }, 1.0f, false, 0.5f)
            );

            colours.append ({
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                255
            });

            outlines.append (Raylib.WHITE);
        }

        BLOCK_TIMER ("physics step", TimeMeasure.MILLISECONDS, () => {
            world.step (Raylib.get_frame_time (), 1);
        });

        for (int i = 0; i < world.body_count; i ++) {
            PhysicsBody body;

            if (world.get_body (i, out body)) {
                AABB box = body.get_AABB ();

                if (box.minimum.y >= 768) {
                    world.remove_body (body);
                    colours.remove (colours.nth_data (i));
                    outlines.remove (outlines.nth_data (i));
                }
            }
        }
    }

    public static void draw_game () {
        for (int i = 0; i < world.body_count; i++) {
            PhysicsBody body;

            if (world.get_body (i, out body)) {
                if (body.shape_type == ShapeType.CIRCLE) {
                    Raylib.draw_circle_vector ({ body.position.x, body.position.y }, body.radius, colours.nth_data (i));
                    Raylib.draw_circle_sector_lines ({ body.position.x, body.position.y }, body.radius, 0.0f, 360.0f, 26, outlines.nth_data (i));
                } else if (body.shape_type == ShapeType.BOX) {
                    draw_polygon_filled (body.get_transformed_vertices (), colours.nth_data (i));
                    draw_polygon_outline (body.get_transformed_vertices (), outlines.nth_data (i));
                }
            }
        }

        for (int i = 0; i < world.contact_list.length (); i++) {
            Vector2 contact = world.contact_list.nth_data (i);

            Raylib.draw_circle_vector ({ contact.x, contact.y }, 8, Raylib.YELLOW);
            Raylib.draw_circle_sector_lines ({ contact.x, contact.y }, 8, 0.0f, 360.0f, 16, Raylib.BLACK);
        }

        Raylib.draw_text ("Body Count: %u".printf (world.body_count), 8, 8, 30, Raylib.WHITE);
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
}
