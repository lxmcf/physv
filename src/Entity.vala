namespace Physv {
    public class Entity {
        public PhysicsBody body { get; private set; }
        public Raylib.Color colour { get; private set; }

        public Entity (PhysicsWorld world, PhysicsBody body, Raylib.Color colour) {
            this.body = body;
            this.colour = colour;

            world.add_body (body);
        }

        public Entity.circle (PhysicsWorld world, float radius, bool is_static, Vector2 position) {
            body = PhysicsBody.create_circle_body (radius, 2.0f, is_static, 0.5f);

            body.move_to (position);
            world.add_body (body);

            colour = _get_random_colour ();
        }

        public Entity.box (PhysicsWorld world, float width, float height, bool is_static, Vector2 position) {
            body = PhysicsBody.create_box_body (width, height, 2.0f, is_static, 0.5f);

            body.move_to (position);
            world.add_body (body);

            colour = _get_random_colour ();
        }

        public void draw () {
            if (body.shape_type == ShapeType.CIRCLE) {
                Raylib.draw_circle_vector ({ body.position.x * PHYSICS_SCALE, body.position.y * PHYSICS_SCALE }, body.radius * PHYSICS_SCALE, colour);
                Raylib.draw_circle_lines ((int)(body.position.x * PHYSICS_SCALE), (int)(body.position.y * PHYSICS_SCALE), body.radius * PHYSICS_SCALE, Raylib.WHITE);

                Vector2 start = Vector2.ZERO;
                Vector2 end = { body.radius, 0.0f };

                Transform transform = Transform (body.position, body.angle);
                start = Vector2.transform (start, transform);
                end = Vector2.transform (end, transform);

                Raylib.draw_line_vector ({ start.x * PHYSICS_SCALE, start.y * PHYSICS_SCALE }, { end.x * PHYSICS_SCALE, end.y * PHYSICS_SCALE }, Raylib.WHITE);
            } else if (body.shape_type == ShapeType.BOX) {
                draw_polygon_filled (body.get_transformed_vertices (), colour);
                draw_polygon_outline (body.get_transformed_vertices (), Raylib.WHITE);
            }
        }

        private Raylib.Color _get_random_colour () {
            return {
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                (uchar)Raylib.get_random_value (0, 255),
                255
            };
        }
    }
}
