namespace Physv {
    public class PhysicsWorld {
        private List<PhysicsBody> body_list;
        private Vector2 gravity;

        public uint body_count {
            get { return body_list.length (); }
        }

        public PhysicsWorld () {
            gravity = { 0.0f, 9.81f };

            body_list = new List<PhysicsBody> ();
        }

        public void add_body (PhysicsBody body) {
            body_list.append (body);
        }

        public void remove_body (PhysicsBody body) {
            body_list.remove (body);
        }

        public bool get_body (int index, out PhysicsBody body) {
            body = null;

            if (index < 0 || index >= body_list.length ()) return false;

            body = body_list.nth_data (index);

            return true;
        }

        public void step (float time) {
            Vector2 normal;
            float depth;

            //  Movement Step
            for (int i = 0; i < body_list.length (); i++) {
                PhysicsBody body = body_list.nth_data (i);

                body.step (time);
            }

            //  Collision step
            for (int i = 0; i < body_list.length () - 1; i++) {
                PhysicsBody body1 = body_list.nth_data (i);

                for (int j = i + 1; j < body_list.length (); j++) {
                    PhysicsBody body2 = body_list.nth_data (j);

                    if (collide (body1, body2, out normal, out depth)) {
                        body1.move (Vector2.multiply_value ({ -normal.x, -normal.y }, depth / 2));
                        body2.move (Vector2.multiply_value ({ normal.x, normal.y }, depth / 2));
                    }
                }
            }
        }

        public bool collide (PhysicsBody body1, PhysicsBody body2, out Vector2 normal, out float depth) {
            normal = Vector2.ZERO;
            depth = 0.0f;

            ShapeType shape1 = body1.shape_type;
            ShapeType shape2 = body2.shape_type;

            if (shape1 == ShapeType.BOX) {
                if (shape2 == ShapeType.BOX) {
                    return intersect_polygons (body1.get_transformed_vertices (), body2.get_transformed_vertices (), out normal, out depth);
                } else if (shape2 == ShapeType.CIRCLE) {
                    bool result = intersect_circle_polygon (body2.position, body2.radius, body1.get_transformed_vertices (), out normal, out depth);
                    normal = { -normal.x, -normal.y };

                    return result;
                }
            } else if (shape1 == ShapeType.CIRCLE) {
                if (shape2 == ShapeType.BOX) {
                    return intersect_circle_polygon (body1.position, body1.radius, body2.get_transformed_vertices (), out normal, out depth);
                } else if (shape2 == ShapeType.CIRCLE) {
                    return intersect_circles (body1.position, body1.radius, body2.position, body2.radius, out normal, out depth);
                }
            }

            return false;
        }
    }
}
