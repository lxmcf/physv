namespace Physv {
    //  TODO: Remove automass
    //  private const float MASS_SCALE = 3200.0f;

    private const float MASS_SCALE = 1.0f;

    public enum ShapeType {
        CIRCLE = 0,
        BOX
    }

    public class PhysicsBody {
        public Vector2 position { public get; private set; }
        public Vector2 linear_velocity { public get; internal set; }

        private float angle;
        private float angular_velocity;

        private Vector2 force;

        public float density { public get; private set; }
        public float mass { public get; private set; }
        public float inverse_mass { public get; private set; }
        public float restitution { public get; private set; }
        public float area { public get; private set; }

        public float inertia { public get; private set; }
        public float inverse_inertia { public get; private set; }

        public bool is_static { public get; private set; }

        public float radius { public get; private set; }
        public float width { public get; private set; }
        public float height { public get; private set; }

        private Vector2[] vertices;
        private Vector2[] transformed_vertices;

        private AABB aabb;

        private bool transform_update_required;
        private bool aabb_update_required;

        public ShapeType shape_type { public get; private set; }

        private PhysicsBody (Vector2 position, float density, float mass, float inertia, float restitution, float area, bool is_static, float radius, float width, float height, Vector2[] vertices, ShapeType shape_type) {
            this.position = position;
            this.linear_velocity = Vector2.ZERO;
            this.angle = 0.0f;
            this.angular_velocity = 0.0f;

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

            this.inertia = inertia;

            if (this.is_static) {
                this.inverse_mass = 0.0f;
                this.inverse_inertia = 0.0f;
            } else {
                this.inverse_mass = 1.0f / this.mass;
                this.inverse_inertia = 1.0f / inertia;
            }

            print ("Mass: %.3f : Inertia: %.3f\n", mass, inertia);


            if (shape_type == ShapeType.BOX) {
                this.vertices = vertices;
                transformed_vertices = new Vector2[4];
            } else {
                vertices = null;
                transformed_vertices = null;
            }

            transform_update_required = true;
            aabb_update_required = true;
        }

        public Vector2[] get_transformed_vertices () {
            if (transform_update_required) {
                Transform transform = Transform (position, angle);

                for (int i = 0; i < vertices.length; i++) {
                    transformed_vertices[i] = Vector2.transform (vertices[i], transform);
                }

                transform_update_required = false;
            }

            return transformed_vertices;
        }

        public AABB get_AABB () {
            if (aabb_update_required) {
                Vector2 minimum = Vector2.MAX;
                Vector2 maximum = Vector2.MIN;

                if (shape_type == ShapeType.BOX) {
                    Vector2[] local_vertices = get_transformed_vertices ();

                    for (int i = 0; i < local_vertices.length; i++) {
                        Vector2 vertex = local_vertices[i];

                        if (vertex.x < minimum.x) minimum.x = vertex.x;
                        if (vertex.x > maximum.x) maximum.x = vertex.x;

                        if (vertex.y < minimum.y) minimum.y = vertex.y;
                        if (vertex.y > maximum.y) maximum.y = vertex.y;
                    }
                } else {
                    minimum.x = position.x - radius;
                    minimum.y = position.y - radius;

                    maximum.x = position.x + radius;
                    maximum.y = position.y + radius;
                }

                aabb = { minimum, maximum };

                aabb_update_required = false;
            }

            return aabb;
        }

        internal void step (float time, Vector2 gravity, int iterations) {
            Vector2 acceleration = Vector2.divide_value (force, mass);
            linear_velocity = Vector2.add (linear_velocity, Vector2.multiply_value (acceleration, time));

            if (is_static) return;

            time /= (float)iterations;

            linear_velocity = Vector2.add (linear_velocity, Vector2.multiply_value (gravity, time));

            position = Vector2.add (position, Vector2.multiply_value (linear_velocity, time));

            angle += angular_velocity * time;

            force = Vector2.ZERO;
            transform_update_required = true;
            aabb_update_required = true;
        }

        public void move (Vector2 amount) {
            position = Vector2.add (position, amount);
            transform_update_required = true;
            aabb_update_required = true;
        }

        public void move_to (Vector2 position) {
            this.position = position;
            transform_update_required = true;
            aabb_update_required = true;
        }

        public void rotate (float amount) {
            angle += amount;
            transform_update_required = true;
            aabb_update_required = true;
        }

        public void rotate_to (float amount) {
            angle = amount;
            transform_update_required = true;
            aabb_update_required = true;
        }

        public void add_force (Vector2 force) {
            this.force = force;
        }

        public static PhysicsBody create_box_body (float width, float height, Vector2 position, float density, bool is_static, float restitution) {
            float area = width * height;

            float mass = area * density;
            float inertia = (1.0f / 12.0f) * mass * ((width * width) + (height * height));

            float left = -width / 2.0f;
            float right = left + width;

            float top = -height / 2.0f;
            float bottom = top + height;

            Vector2[] vertices = new Vector2[4];
            vertices[0] = { left, top };
            vertices[1] = { right, top };
            vertices[2] = { right, bottom };
            vertices[3] = { left, bottom };

            return new PhysicsBody (position, density, mass, inertia, restitution, area, is_static, 0.0f, width, height, vertices, ShapeType.BOX);
        }

        public static PhysicsBody create_circle_body (float radius, Vector2 position, float density, bool is_static, float restitution) {
            float area = radius * radius * (float)Math.PI;

            float mass = area * density;
            float inertia = (1.0f / 12.0f) * mass * (radius * radius);

            return new PhysicsBody (position, density, mass, inertia, restitution, area, is_static, radius, 0.0f, 0.0f, { }, ShapeType.CIRCLE);
        }
    }
}
