using Physv.Debug;

namespace Physv {
    private struct ContactPair {
        public int contact1;
        public int contact2;
    }

    public class PhysicsWorld {
        private List<PhysicsBody> body_list;
        private List<Manifold?> manifold_list;

        private List<ContactPair?> contact_pairs;

        private Vector2 gravity;

        public uint body_count {
            get { return body_list.length (); }
        }

        public PhysicsWorld () {
            gravity = { 0.0f, 9.81f };

            body_list = new List<PhysicsBody> ();
            manifold_list = new List<Manifold?> ();

            contact_pairs = new List<ContactPair?> ();
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
            for (int current_iteraton = 0; current_iteraton < iterations; current_iteraton++) {
                contact_pairs = new List<ContactPair?> ();
                manifold_list = new List<Manifold?> ();

                //  Movement Step
                step_bodies (time, iterations);

                //  Collision step
                broad_phase ();
                narrow_phase ();
            }
        }

        //  TODO: Optimise... Like crazy
        private void broad_phase () {
            AABB body1_aabb;
            AABB body2_aabb;

            PhysicsBody body1;
            PhysicsBody body2;

            for (int i = 0; i < body_list.length () - 1; i++) {
                body1 = body_list.nth_data (i);
                body1_aabb = body1.get_AABB ();

                for (int j = i + 1; j < body_list.length (); j++) {
                    body2 = body_list.nth_data (j);
                    body2_aabb = body2.get_AABB ();

                    if (body1.is_static && body2.is_static) continue;

                    if (!intersect_AABB (body1_aabb, body2_aabb)) continue;

                    contact_pairs.append ({ i, j});
                }
            }
        }

        private void step_bodies (float time, int iterations) {
            for (int i = 0; i < body_list.length (); i++) {
                PhysicsBody body = body_list.nth_data (i);

                body.step (time, gravity, iterations);
            }
        }

        private void narrow_phase () {
            ContactPair contact_pair;
            PhysicsBody body1;
            PhysicsBody body2;

            Vector2 normal;
            float depth;

            for (int i = 0; i < contact_pairs.length (); i++) {
                contact_pair = contact_pairs.nth_data (i);

                body1 = body_list.nth_data (contact_pair.contact1);
                body2 = body_list.nth_data (contact_pair.contact2);

                if (collide (body1, body2, out normal, out depth)) {
                    seperate_bodies (body1, body2, Vector2.multiply_value (normal, depth));

                    Manifold manifold = { };
                    manifold.body1 = body1;
                    manifold.body2 = body2;
                    manifold.depth = depth;
                    manifold.normal = normal;

                    find_contact_points (body1, body2, out manifold.contact1, out manifold.contact2, out manifold.contact_count);

                    resolve_collision (manifold);
                }
            }
        }

        private void seperate_bodies (PhysicsBody body1, PhysicsBody body2, Vector2 minimum_translation) {
            if (body1.is_static) {
                body2.move (minimum_translation);
            } else if (body2.is_static) {
                body1.move ({ -minimum_translation.x, -minimum_translation.y });
            } else {
                body1.move (Vector2.divide_value ({ -minimum_translation.x, -minimum_translation.y }, 2));
                body2.move (Vector2.divide_value (minimum_translation, 2));
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
