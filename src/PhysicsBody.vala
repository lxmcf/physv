namespace Physv {
    //  TODO: Remove automass
    private const float MASS_SCALE = 3200.0f;

    public enum ShapeType {
        CIRCLE = 0,
        BOX,
        POLYGON
    }

    public class PhysicsBody {
        public Vector2 position { public get; private set; }
        public Vector2 linear_velocity { public get; internal set; }

        private float rotation;
        private float rotational_velocity;

        private Vector2 force;

        public float density { public get; private set; }
        public float mass { public get; private set; }
        public float restitution { public get; private set; }
        public float area { public get; private set; }

        public bool is_static { public get; private set; }

        public float radius { public get; private set; }
        public float width { public get; private set; }
        public float height { public get; private set; }

        private Vector2[] vertices;
        private Vector2[] transformed_vertices;

        public int[] indices;

        private bool transform_update_required;

        public ShapeType shape_type { public get; private set; }

        private PhysicsBody (Vector2 position, float density, float mass, float restitution, float area, bool is_static, float radius, float width, float height, ShapeType shape_type) {
            this.position = position;
            this.linear_velocity = Vector2.ZERO;
            this.rotation = 0.0f;
            this.rotational_velocity = 0.0f;

            this.force = Vector2.ZERO;

            this.density = density;
            this.mass = mass;
            this.restitution = restitution;
            this.area = area;

            this.is_static = is_static;
            this.radius = radius;
            this.width = width;
            this.height = height;

            this.shape_type = shape_type;

            if (shape_type == ShapeType.BOX) {
                float left = -width / 2.0f;
                float right = left + width;

                float top = -height / 2.0f;
                float bottom = top + height;

                vertices = new Vector2[4];
                vertices[0] = { left, top };
                vertices[1] = { right, top };
                vertices[2] = { right, bottom };
                vertices[3] = { left, bottom };

                transformed_vertices = new Vector2[4];

                indices = new int[6];
                indices[0] = 0;
                indices[1] = 1;
                indices[2] = 2;
                indices[3] = 0;
                indices[4] = 2;
                indices[5] = 3;
            } else {
                vertices = null;
                transformed_vertices = null;
                indices = null;
            }

            transform_update_required = true;
        }

        public Vector2[] get_transformed_vertices () {
            if (transform_update_required) {
                Transform transform = Transform (position, rotation);

                for (int i = 0; i < vertices.length; i++) {
                    transformed_vertices[i] = Vector2.transform (vertices[i], transform);
                }
            }

            return transformed_vertices;
        }

        public void step (float time) {
            Vector2 acceleration = Vector2.divide_value (force, mass);
            linear_velocity = Vector2.add (linear_velocity, Vector2.multiply_value (acceleration, time));

            position = Vector2.add (position, Vector2.multiply_value (linear_velocity, time));

            rotation += rotational_velocity * time;

            force = Vector2.ZERO;
            transform_update_required = true;
        }

        public void move (Vector2 amount) {
            position = Vector2.add (position, amount);
            transform_update_required = true;
        }

        public void move_to (Vector2 position) {
            this.position = position;
            transform_update_required = true;
        }

        public void rotate (float amount) {
            rotation += amount;
            transform_update_required = true;
        }

        public void add_force (Vector2 force) {
            this.force = force;
        }

        public static PhysicsBody create_box_body (float width, float height, Vector2 position, float density, bool is_static, float restitution) {
            float area = width * height;
            float mass = area * density;

            return new PhysicsBody (position, density, mass / MASS_SCALE, restitution, area, is_static, 0.0f, width, height, ShapeType.BOX);
        }

        public static PhysicsBody create_circle_body (float radius, Vector2 position, float density, bool is_static, float restitution) {
            float area = radius * radius * (float)Math.PI;
            float mass = area * density;

            return new PhysicsBody (position, density, mass / MASS_SCALE, restitution, area, is_static, radius, 0.0f, 0.0f, ShapeType.CIRCLE);
        }
    }
}
