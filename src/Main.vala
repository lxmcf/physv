using Physv.Debug;

private const int PHYSICS_SCALE = 32;
private const int WORLD_STEPS = 8;

namespace Physv {
    private List<Entity> entities;

    private PhysicsWorld world;

    private string elapsed_time;

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
        entities = new List<Entity> ();
        world = new PhysicsWorld ();

        PhysicsBody ground = PhysicsBody.create_box_body (32.0f, 3.0f, 1.0f, true, 0.5f);
        ground.move_to ({ 20.0f, 20.0f });
        entities.append (new Entity (world, ground, Raylib.DARKGRAY));

        PhysicsBody edge1 = PhysicsBody.create_box_body (10.0f, 2.0f, 1.0f, true, 0.5f);
        edge1.move_to ({ 7.5f, 7.5f });
        edge1.rotate ((float)Math.PI_2 / 20f);
        entities.append (new Entity (world, edge1, Raylib.DARKGRAY));

        PhysicsBody edge2 = PhysicsBody.create_box_body (15.0f, 2.0f, 1.0f, true, 0.5f);
        edge2.move_to ({ 32.0f, 11.25f });
        edge2.rotate (-(float)Math.PI_2 / 20f); // vala-lint=space-before-paren
        entities.append (new Entity (world, edge2, Raylib.DARKGRAY));
    }

    public static void update_game () {
        if (Raylib.is_mouse_button_pressed (Raylib.MouseButton.LEFT)) {
            float width = (float)Random.double_range (2, 3);
            float height = (float)Random.double_range (2, 3);

            Raylib.Vector2 mouse = Raylib.get_mouse_position ();

            Entity box = new Entity.box (world, width, height, false, { mouse.x / 32.0f, mouse.y / 32.0f });
            entities.append (box);
        }

        if (Raylib.is_mouse_button_pressed (Raylib.MouseButton.RIGHT)) {
            float radius = (float)Random.double_range (1, 1.25);

            Raylib.Vector2 mouse = Raylib.get_mouse_position ();

            Entity circle = new Entity.circle (world, radius, false, { mouse.x / 32.0f, mouse.y / 32.0f });
            entities.append (circle);
        }

        elapsed_time = BLOCK_TIMER ("physics step", TimeMeasure.MILLISECONDS, () => {
            world.step (Raylib.get_frame_time (), WORLD_STEPS);
        });

        int body_count = 0;

        for (int i = 0; i < entities.length (); i ++) {
            Entity entity = entities.nth_data (i);
            PhysicsBody body = entity.body;

            if (body.is_static) continue;

            AABB box = body.get_AABB ();

            if (box.minimum.y >= Raylib.get_render_height () / 32) {
                body_count++;

                world.remove_body (entity.body);
                entities.remove (entity);
            }
        }
    }

    public static void draw_game () {
        for (int i = 0; i < entities.length (); i++) {
            Entity entity = entities.nth_data (i);

            entity.draw ();
        }

        Raylib.draw_text ("Physics Step: %s ms".printf (elapsed_time), 8, 8, 30, Raylib.WHITE);
        Raylib.draw_text ("Entity Count: %u".printf (entities.length ()), 8, 38, 30, Raylib.WHITE);
        Raylib.draw_text ("Body Count: %u".printf (world.body_count), 8, 68, 30, Raylib.WHITE);
    }
}
