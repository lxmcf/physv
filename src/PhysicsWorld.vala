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

                    resolve_collision_full (manifold);
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
            float magnitude = -(1f + restitution) * Vector2.dot (relative_velocity, normal); // vala-lint=space-before-paren
            magnitude /= body1.inverse_mass + body2.inverse_mass;

            Vector2 impulse = Vector2.multiply_value (normal, magnitude);

            body1.linear_velocity = Vector2.subtract (body1.linear_velocity, Vector2.multiply_value (impulse, body1.inverse_mass));
            body2.linear_velocity = Vector2.add (body2.linear_velocity, Vector2.multiply_value (impulse, body2.inverse_mass));
        }

        public void resolve_collision_ext (Manifold manifold) {
            PhysicsBody body1 = manifold.body1;
            PhysicsBody body2 = manifold.body2;

            Vector2 normal = manifold.normal;
            Vector2 contact1 = manifold.contact1;
            Vector2 contact2 = manifold.contact2;
            int contact_count = manifold.contact_count;

            float restitution = Math.fminf (body1.restitution, body2.restitution);

            Vector2[] contact_list = { contact1, contact2 };
            Vector2[] impulse_list = new Vector2[2];
            Vector2[] r1_list = new Vector2[2];
            Vector2[] r2_list = new Vector2[2];


            for (int i = 0; i < contact_count; i++) {
                Vector2 r1 = Vector2.subtract (contact_list[i], body1.position);
                Vector2 r2 = Vector2.subtract (contact_list[i], body2.position);

                r1_list[i] = r1;
                r2_list[i] = r2;

                Vector2 r1_perp = { -r1.y, r1.x };
                Vector2 r2_perp = { -r2.y, r2.x };

                Vector2 r1_angular_velocity = Vector2.multiply_value (r1_perp, body1.angular_velocity);
                Vector2 r2_angular_velocity = Vector2.multiply_value (r2_perp, body2.angular_velocity);

                Vector2 relative_velocity = Vector2.subtract (
                    Vector2.add (body2.linear_velocity, r2_angular_velocity),
                    Vector2.add (body1.linear_velocity, r1_angular_velocity)
                );

                float contact_velocity_magnitude = Vector2.dot (relative_velocity, normal);

                if (contact_velocity_magnitude > 0.0f) {
                    continue;
                }

                float r1_perp_dot = Vector2.dot (r1_perp, normal);
                float r2_perp_dot = Vector2.dot (r2_perp, normal);

                float denominator = body1.inverse_mass + body2.inverse_mass +
                                    (r1_perp_dot * r1_perp_dot) * body1.inverse_inertia +
                                    (r2_perp_dot * r2_perp_dot) * body2.inverse_inertia;

                float magnitude = -(1f + restitution) * contact_velocity_magnitude; // vala-lint=space-before-paren
                magnitude /= denominator;
                magnitude /= contact_count;

                Vector2 impulse = Vector2.multiply_value (normal, magnitude);

                impulse_list[i] = impulse;
            }

            for (int i = 0; i < contact_count; i++) {
                Vector2 impulse = impulse_list[i];

                Vector2 r1 = r1_list[i];
                Vector2 r2 = r2_list[i];

                body1.linear_velocity = Vector2.add (body1.linear_velocity, Vector2.multiply_value (impulse.inverse, body1.inverse_mass));
                body1.angular_velocity += -Vector2.cross (r1, impulse) * body1.inverse_inertia;

                body2.linear_velocity = Vector2.add (body2.linear_velocity, Vector2.multiply_value (impulse, body2.inverse_mass));
                body2.angular_velocity += Vector2.cross (r2, impulse) * body2.inverse_inertia;
            }
        }

        public void resolve_collision_full (Manifold manifold) {
            PhysicsBody body1 = manifold.body1;
            PhysicsBody body2 = manifold.body2;

            Vector2 normal = manifold.normal;
            Vector2 contact1 = manifold.contact1;
            Vector2 contact2 = manifold.contact2;
            int contact_count = manifold.contact_count;

            float restitution = Math.fminf (body1.restitution, body2.restitution);

            float static_friction = (body1.static_friction + body2.static_friction) / 2.0f;
            float dynamic_friction = (body1.dynamic_friction + body2.dynamic_friction) / 2.0f;

            Vector2[] contact_list = { contact1, contact2 };
            Vector2[] impulse_list = new Vector2[2];
            Vector2[] friction_impulse_list = new Vector2[2];
            Vector2[] r1_list = new Vector2[2];
            Vector2[] r2_list = new Vector2[2];

            float[] magnitude_list = new float[2];

            //----------------------------------------------------------------------------------
            // LOOP 1
            //----------------------------------------------------------------------------------
            for (int i = 0; i < contact_count; i++) {
                Vector2 r1 = Vector2.subtract (contact_list[i], body1.position);
                Vector2 r2 = Vector2.subtract (contact_list[i], body2.position);

                r1_list[i] = r1;
                r2_list[i] = r2;

                Vector2 r1_perp = { -r1.y, r1.x };
                Vector2 r2_perp = { -r2.y, r2.x };

                Vector2 r1_angular_velocity = Vector2.multiply_value (r1_perp, body1.angular_velocity);
                Vector2 r2_angular_velocity = Vector2.multiply_value (r2_perp, body2.angular_velocity);

                Vector2 relative_velocity = Vector2.subtract (
                    Vector2.add (body2.linear_velocity, r2_angular_velocity),
                    Vector2.add (body1.linear_velocity, r1_angular_velocity)
                );

                float contact_velocity_magnitude = Vector2.dot (relative_velocity, normal);

                if (contact_velocity_magnitude > 0.0f) {
                    continue;
                }

                float r1_perp_dot = Vector2.dot (r1_perp, normal);
                float r2_perp_dot = Vector2.dot (r2_perp, normal);

                float denominator = body1.inverse_mass + body2.inverse_mass +
                                    (r1_perp_dot * r1_perp_dot) * body1.inverse_inertia +
                                    (r2_perp_dot * r2_perp_dot) * body2.inverse_inertia;

                float magnitude = -(1f + restitution) * contact_velocity_magnitude; // vala-lint=space-before-paren
                magnitude /= denominator;
                magnitude /= contact_count;

                magnitude_list[i] = magnitude;

                Vector2 impulse = Vector2.multiply_value (normal, magnitude);

                impulse_list[i] = impulse;
            }

            for (int i = 0; i < contact_count; i++) {
                Vector2 impulse = impulse_list[i];

                Vector2 r1 = r1_list[i];
                Vector2 r2 = r2_list[i];

                body1.linear_velocity = Vector2.add (body1.linear_velocity, Vector2.multiply_value (impulse.inverse, body1.inverse_mass));
                body1.angular_velocity += -Vector2.cross (r1, impulse) * body1.inverse_inertia;

                body2.linear_velocity = Vector2.add (body2.linear_velocity, Vector2.multiply_value (impulse, body2.inverse_mass));
                body2.angular_velocity += Vector2.cross (r2, impulse) * body2.inverse_inertia;
            }

            //----------------------------------------------------------------------------------
            // LOOP 2
            //----------------------------------------------------------------------------------
            for (int i = 0; i < contact_count; i++) {
                Vector2 r1 = Vector2.subtract (contact_list[i], body1.position);
                Vector2 r2 = Vector2.subtract (contact_list[i], body2.position);

                r1_list[i] = r1;
                r2_list[i] = r2;

                Vector2 r1_perp = { -r1.y, r1.x };
                Vector2 r2_perp = { -r2.y, r2.x };

                Vector2 r1_angular_velocity = Vector2.multiply_value (r1_perp, body1.angular_velocity);
                Vector2 r2_angular_velocity = Vector2.multiply_value (r2_perp, body2.angular_velocity);

                Vector2 relative_velocity = Vector2.subtract (
                    Vector2.add (body2.linear_velocity, r2_angular_velocity),
                    Vector2.add (body1.linear_velocity, r1_angular_velocity)
                );

                float relative_velocity_dot = Vector2.dot (relative_velocity, normal);

                Vector2 tangent = Vector2.subtract (relative_velocity, Vector2.multiply_value (normal, relative_velocity_dot));

                if (Vector2.equals_rough (tangent, Vector2.ZERO)) {
                    continue;
                } else {
                    tangent = Vector2.normalise (tangent);
                }

                float r1_perp_dot = Vector2.dot (r1_perp, tangent);
                float r2_perp_dot = Vector2.dot (r2_perp, tangent);

                float denominator = body1.inverse_mass + body2.inverse_mass +
                                    (r1_perp_dot * r1_perp_dot) * body1.inverse_inertia +
                                    (r2_perp_dot * r2_perp_dot) * body2.inverse_inertia;

                float contact_velocity_magnitude = Vector2.dot (relative_velocity, tangent);

                float tangent_magnitude = -Vector2.dot (relative_velocity, tangent);
                tangent_magnitude /= denominator;
                tangent_magnitude /= contact_count;

                Vector2 friction_impulse;
                float magnitude = magnitude_list[i];

                if (Math.fabsf (tangent_magnitude) <= magnitude * static_friction) {
                    friction_impulse = Vector2.multiply_value (normal, tangent_magnitude);
                } else {
                    friction_impulse = Vector2.multiply_value (Vector2.multiply_value (tangent, dynamic_friction), -magnitude);
                }

                friction_impulse_list[i] = friction_impulse;
            }

            for (int i = 0; i < contact_count; i++) {
                Vector2 friction_impulse = friction_impulse_list[i];

                Vector2 r1 = r1_list[i];
                Vector2 r2 = r2_list[i];

                body1.linear_velocity = Vector2.add (body1.linear_velocity, Vector2.multiply_value (friction_impulse.inverse, body1.inverse_mass));
                body1.angular_velocity += -Vector2.cross (r1, friction_impulse) * body1.inverse_inertia;

                body2.linear_velocity = Vector2.add (body2.linear_velocity, Vector2.multiply_value (friction_impulse, body2.inverse_mass));
                body2.angular_velocity += Vector2.cross (r2, friction_impulse) * body2.inverse_inertia;
            }
        }
    }
}
