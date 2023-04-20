namespace Physv {
    public class PhysicsWorld {
        private List<PhysicsBody> body_list;
        private List<Manifold?> manifold_list;

        public List<Vector2?> contact_list;

        private Vector2 gravity;

        public uint body_count {
            get { return body_list.length (); }
        }

        public PhysicsWorld () {
            gravity = { 0.0f, 200.0f };

            body_list = new List<PhysicsBody> ();
            manifold_list = new List<Manifold?> ();

            contact_list = new List<Vector2?> ();
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

        public void step (float time, int iterations) {
            Vector2 normal;
            float depth;

            contact_list = new List<Vector2?> ();

            for (int k = 0; k < iterations; k++) {
                //  Movement Step
                for (int i = 0; i < body_list.length (); i++) {
                    PhysicsBody body = body_list.nth_data (i);

                    body.step (time, gravity, iterations);
                }

                manifold_list = new List<Manifold?> ();

                //  Collision step
                for (int i = 0; i < body_list.length () - 1; i++) {
                    PhysicsBody body1 = body_list.nth_data (i);
                    AABB body1_aabb = body1.get_AABB ();

                    for (int j = i + 1; j < body_list.length (); j++) {
                        PhysicsBody body2 = body_list.nth_data (j);
                        AABB body2_aabb = body2.get_AABB ();

                        if (body1.is_static && body2.is_static) continue;

                        if (!intersect_AABB (body1_aabb, body2_aabb)) continue;

                        if (collide (body1, body2, out normal, out depth)) {
                            if (body1.is_static) {
                                body2.move (Vector2.multiply_value (normal, depth));
                            } else if (body2.is_static) {
                                body1.move (Vector2.multiply_value ({ -normal.x, -normal.y }, depth / 2));
                            } else {
                                body1.move (Vector2.multiply_value ({ -normal.x, -normal.y }, depth / 2));
                                body2.move (Vector2.multiply_value (normal, depth / 2));
                            }

                            Manifold manifold = { };
                            manifold.body1 = body1;
                            manifold.body2 = body2;
                            manifold.depth = depth;
                            manifold.normal = normal;

                            find_contact_points (body1, body2, out manifold.contact1, out manifold.contact2, out manifold.contact_count);

                            manifold_list.append (manifold);
                        }
                    }
                }

                for (int i = 0; i < manifold_list.length (); i++) {
                    Manifold manifold = manifold_list.nth_data (i);

                    resolve_collision (manifold);

                    if (manifold.contact_count > 0) {
                        contact_list.append (manifold.contact1);

                        if (manifold.contact_count > 1) {
                            contact_list.append (manifold.contact2);
                        }
                    }
                }
            }
        }

        public void resolve_collision (Manifold manifold) {
            PhysicsBody body1 = manifold.body1;
            PhysicsBody body2 = manifold.body2;

            Vector2 normal = manifold.normal;

            Vector2 relative_velocity = Vector2.subtract (body2.linear_velocity, body1.linear_velocity);

            if (Vector2.dot (relative_velocity, normal) > 0) return;

            float restitution = Math.fminf (body1.restitution, body2.restitution);
            float j = -(1f + restitution) * Vector2.dot (relative_velocity, normal); // vala-lint=space-before-paren
            j /= body1.inverse_mass + body2.inverse_mass;

            Vector2 impulse = Vector2.multiply_value (normal, j);

            body1.linear_velocity = Vector2.subtract (body1.linear_velocity, Vector2.multiply_value (impulse, body1.inverse_mass));
            body2.linear_velocity = Vector2.add (body2.linear_velocity, Vector2.multiply_value (impulse, body2.inverse_mass));
        }
    }
}
