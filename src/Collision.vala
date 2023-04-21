namespace Physv {
    public static void point_segment_distance (Vector2 point, Vector2 start, Vector2 end, out float distance, out Vector2 contact_point) {
        Vector2 ab = Vector2.subtract (end, start);
        Vector2 ap = Vector2.subtract (point, start);

        float projection = Vector2.dot (ap, ab);
        float ab_length_squared = Vector2.length_squared (ab);
        float d = projection / ab_length_squared;

        if (d <= 0f) {
            contact_point = start;
        } else if (d >= 1f) {
            contact_point = end;
        } else {
            contact_point = Vector2.add (start, Vector2.multiply_value (ab, d));
        }

        distance = Vector2.distance_squared (point, contact_point);
    }

    //  NOTE: I think my math may be off here
    public static bool intersect_AABB (AABB box1, AABB box2) {
        bool gap_x = (box1.maximum.x <= box2.minimum.x || box2.maximum.x <= box1.minimum.x);
        bool gap_y = (box1.maximum.y <= box2.minimum.y || box2.maximum.y <= box1.minimum.y);

        if (gap_x || gap_y) {
            return false;
        }

        return true;
    }

    public static void find_contact_points (PhysicsBody body1, PhysicsBody body2, out Vector2 contact1, out Vector2 contact2, out int contact_count) {
        contact1 = Vector2.ZERO;
        contact2 = Vector2.ZERO;
        contact_count = 0;

        ShapeType shape1 = body1.shape_type;
        ShapeType shape2 = body2.shape_type;

        if (shape1 == ShapeType.BOX) {
            if (shape2 == ShapeType.BOX) {
                find_contact_point_polygons (body1.get_transformed_vertices (), body2.get_transformed_vertices (), out contact2, out contact1, out contact_count);
            } else if (shape2 == ShapeType.CIRCLE) {
                find_contact_point_polygon_circle (body2.position, body2.radius, body1.position, body1.get_transformed_vertices (), out contact1);

                contact_count = 1;
            }
        } else if (shape1 == ShapeType.CIRCLE) {
            if (shape2 == ShapeType.BOX) {
                find_contact_point_polygon_circle (body1.position, body1.radius, body2.position, body2.get_transformed_vertices (), out contact1);

                contact_count = 1;
            } else if (shape2 == ShapeType.CIRCLE) {
                find_contact_point_circles (body1.position, body1.radius, body2.position, out contact1);

                contact_count = 1;
            }
        }
    }

    private static void find_contact_point_polygons (Vector2[] vertices1, Vector2[] vertices2, out Vector2 contact_point1, out Vector2 contact_point2, out int contact_count) {
        contact_point1 = Vector2.ZERO;
        contact_point2 = Vector2.ZERO;
        contact_count = 0;

        float distance;
        Vector2 contact_point;

        float minimum_distance = float.MAX;
        float margin = 0.0005f;

        for (int i = 0; i < vertices1.length; i++) {
            Vector2 point = vertices1[i];

            for (int j = 0; j < vertices2.length; j++) {
                Vector2 vertex1 = vertices2[j];
                Vector2 vertex2 = vertices2[(j + 1) % vertices2.length];

                point_segment_distance (point, vertex1, vertex2, out distance, out contact_point);

                bool distance_equals = Math.fabsf (distance - minimum_distance) < margin;

                if (distance_equals) {
                    if (!Vector2.equals_rough (contact_point, contact_point1)) {
                        contact_point2 = contact_point;

                        contact_count = 2;
                    }
                } else if (distance < minimum_distance) {
                    minimum_distance = distance;
                    contact_point1 = contact_point;

                    contact_count = 1;
                }
            }
        }

        for (int i = 0; i < vertices2.length; i++) {
            Vector2 point = vertices2[i];

            for (int j = 0; j < vertices1.length; j++) {
                Vector2 vertex1 = vertices1[j];
                Vector2 vertex2 = vertices1[(j + 1) % vertices1.length];

                point_segment_distance (point, vertex1, vertex2, out distance, out contact_point);

                bool distance_equals = Math.fabsf (distance - minimum_distance) < margin;

                if (distance_equals) {
                    if (!Vector2.equals_rough (contact_point, contact_point1)) {
                        contact_point2 = contact_point;

                        contact_count = 2;
                    }
                } else if (distance < minimum_distance) {
                    minimum_distance = distance;
                    contact_point1 = contact_point;

                    contact_count = 1;
                }
            }
        }
    }

    private static void find_contact_point_circles (Vector2 circle_position1, float circle_radius, Vector2 circle_position2, out Vector2 contact_point) {
        Vector2 direction = Vector2.subtract (circle_position2, circle_position1);
        direction = Vector2.normalise (direction);

        contact_point = Vector2.add (circle_position1, Vector2.multiply_value (direction, circle_radius));
    }

    private static void find_contact_point_polygon_circle (Vector2 circle_position, float circle_radius, Vector2 polygon_position, Vector2[] vertices, out Vector2 contact_point) {
        contact_point = Vector2.ZERO;

        float minimum_distance = float.MAX;
        Vector2 potential_contact;

        for (int i = 0; i < vertices.length; i++) {
            Vector2 start = vertices[i];
            Vector2 end = vertices[(i + 1) % vertices.length];

            float distance;

            point_segment_distance (circle_position, start, end, out distance, out potential_contact);

            if (distance < minimum_distance) {
                minimum_distance = distance;

                contact_point = potential_contact;
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
                return intersect_polygons (body1.position, body1.get_transformed_vertices (), body2.position, body2.get_transformed_vertices (), out normal, out depth);
            } else if (shape2 == ShapeType.CIRCLE) {
                bool result = intersect_circle_polygon (body2.position, body2.radius, body1.position, body1.get_transformed_vertices (), out normal, out depth);
                normal = { -normal.x, -normal.y };

                return result;
            }
        } else if (shape1 == ShapeType.CIRCLE) {
            if (shape2 == ShapeType.BOX) {
                return intersect_circle_polygon (body1.position, body1.radius, body2.position, body2.get_transformed_vertices (), out normal, out depth);
            } else if (shape2 == ShapeType.CIRCLE) {
                return intersect_circles (body1.position, body1.radius, body2.position, body2.radius, out normal, out depth);
            }
        }

        return false;
    }

    public static bool intersect_circle_polygon (Vector2 circle_position, float circle_radius, Vector2 polygon_position, Vector2[] vertices, out Vector2 normal, out float depth) {
        float minimum1, maximum1;
        float minimum2, maximum2;

        normal = Vector2.ZERO;
        depth = float.MAX;

        Vector2 axis = Vector2.ZERO;
        float axis_depth = 0.0f;

        for (int i = 0; i < vertices.length; i++) {
            Vector2 vertex1 = vertices[i];
            Vector2 vertex2 = vertices[(i + 1) % vertices.length];

            Vector2 edge = Vector2.subtract (vertex2, vertex1);
            axis = { -edge.y, edge.x };

            project_vertices (vertices, axis, out minimum1, out maximum1);
            project_circle (circle_position, circle_radius, axis, out minimum2, out maximum2);

            if (minimum1 >= maximum2 || minimum2 >= maximum1) return false;

            axis_depth = Math.fminf (maximum2 - minimum1, maximum1 - minimum2);

            if (axis_depth < depth) {
                depth = axis_depth;
                normal = axis;
            }
        }

        int closest_point = closest_point_on_polygon (circle_position, vertices);

        axis = Vector2.subtract (vertices[closest_point], circle_position);

        project_vertices (vertices, axis, out minimum1, out maximum1);
        project_circle (circle_position, circle_radius, axis, out minimum2, out maximum2);

        if (minimum1 >= maximum2 || minimum2 >= maximum1) return false;

        axis_depth = Math.fminf (maximum2 - minimum1, maximum1 - minimum2);

        if (axis_depth < depth) {
            depth = axis_depth;
            normal = axis;
        }

        //  Need to test perf
        depth /= Vector2.length (normal);
        normal = Vector2.normalise (normal);
        //  Need to test perf

        Vector2 direction = Vector2.subtract (polygon_position, circle_position);

        if (Vector2.dot (direction, normal) < 0.0f) {
            normal = { -normal.x, -normal.y };
        }

        return true;
    }

    public static bool intersect_polygons (Vector2 polygon_position1, Vector2[] vertices1, Vector2 polygon_position2, Vector2[] vertices2, out Vector2 normal, out float depth) {
        float minimum1, maximum1;
        float minimum2, maximum2;

        normal = Vector2.ZERO;
        depth = float.MAX;

        for (int i = 0; i < vertices1.length; i++) {
            Vector2 vertex1 = vertices1[i];
            Vector2 vertex2 = vertices1[(i + 1) % vertices1.length];

            Vector2 edge = Vector2.subtract (vertex2, vertex1);
            Vector2 axis = { -edge.y, edge.x };

            project_vertices (vertices1, axis, out minimum1, out maximum1);
            project_vertices (vertices2, axis, out minimum2, out maximum2);

            if (minimum1 >= maximum2 || minimum2 >= maximum1) return false;

            float axis_depth = Math.fminf (maximum2 - minimum1, maximum1 - minimum2);

            if (axis_depth < depth) {
                depth = axis_depth;
                normal = axis;
            }
        }

        for (int i = 0; i < vertices2.length; i++) {
            Vector2 vertex1 = vertices2[i];
            Vector2 vertex2 = vertices2[(i + 1) % vertices2.length];

            Vector2 edge = Vector2.subtract (vertex2, vertex1);
            Vector2 axis = { -edge.y, edge.x };

            project_vertices (vertices1, axis, out minimum1, out maximum1);
            project_vertices (vertices2, axis, out minimum2, out maximum2);

            if (minimum1 >= maximum2 || minimum2 >= maximum1) return false;

            float axis_depth = Math.fminf (maximum2 - minimum1, maximum1 - minimum2);

            if (axis_depth < depth) {
                depth = axis_depth;
                normal = axis;
            }
        }

        //  Need to test perf
        depth /= Vector2.length (normal);
        normal = Vector2.normalise (normal);
        //  Need to test perf

        Vector2 direction = Vector2.subtract (polygon_position2, polygon_position1);

        if (Vector2.dot (direction, normal) < 0.0f) {
            normal = { -normal.x, -normal.y };
        }

        return true;
    }

    private static void project_vertices (Vector2[] vertices, Vector2 axis, out float minimum, out float maximum) {
        minimum = float.MAX;
        maximum = float.MIN;

        for (int i = 0; i < vertices.length; i++) {
            float projection = Vector2.dot (vertices[i], axis);

            if (projection < minimum) minimum = projection;
            if (projection > maximum) maximum = projection;
        }
    }

    private static int closest_point_on_polygon (Vector2 circle_position, Vector2[] vertices) {
        int result = -1;

        float minimum_distance = float.MAX;

        for (int i = 0; i < vertices.length; i++) {
            float distance = Vector2.distance (vertices[i], circle_position);

            if (distance < minimum_distance) {
                minimum_distance = distance;

                result = i;
            }
        }

        return result;
    }

    private static void project_circle (Vector2 center, float radius, Vector2 axis, out float minimum, out float maximum) {
        Vector2 direction = Vector2.normalise (axis);
        Vector2 direction_and_radius = Vector2.multiply_value (direction, radius);

        Vector2 point1 = Vector2.add (center, direction_and_radius);
        Vector2 point2 = Vector2.subtract (center, direction_and_radius);

        minimum = Vector2.dot (point1, axis);
        maximum = Vector2.dot (point2, axis);

        if (minimum > maximum) {
            float temp = minimum;

            minimum = maximum;
            maximum = temp;
        }
    }

    public static bool intersect_circles (Vector2 circle1, float radius1, Vector2 circle2, float radius2, out Vector2 normal, out float depth) {
        normal = Vector2.ZERO;
        depth = 0.0f;

        float distance = Vector2.distance (circle1, circle2);
        float radii = radius1 + radius2;

        if (distance >= radii) return false;

        normal = Vector2.subtract (circle2, circle1);
        normal = Vector2.normalise (normal);

        depth = radii - distance;

        return true;
    }
}
