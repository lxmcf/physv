namespace Physv {
    public static bool intersect_circle_polygon (Vector2 circle_position, float circle_radius, Vector2[] vertices, out Vector2 normal, out float depth) {
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

        Vector2 polygon_position = find_arithmatic_mean (vertices);

        Vector2 direction = Vector2.subtract (polygon_position, circle_position);

        if (Vector2.dot (direction, normal) < 0.0f) {
            normal = { -normal.x, -normal.y };
        }

        return true;
    }

    public static bool intersect_polygons (Vector2[] vertices1, Vector2[] vertices2, out Vector2 normal, out float depth) {
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

        Vector2 center1 = find_arithmatic_mean (vertices1);
        Vector2 center2 = find_arithmatic_mean (vertices2);

        Vector2 direction = Vector2.subtract (center2, center1);

        if (Vector2.dot (direction, normal) < 0.0f) {
            normal = { -normal.x, -normal.y };
        }

        return true;
    }

    private static Vector2 find_arithmatic_mean (Vector2[] vertices) {
        Vector2 sum = Vector2.ZERO;

        for (int i = 0; i < vertices.length; i++) {
            sum = Vector2.add (sum, vertices[i]);
        }

        return Vector2.divide_value (sum, vertices.length);
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
