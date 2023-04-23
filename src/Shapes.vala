namespace Physv {
    public static void draw_polygon_outline (Vector2[] vertices, Raylib.Color color) {
        for (int i = 0; i < vertices.length; i++) {
            Vector2 start = vertices[i];
            Vector2 end = vertices[(i + 1) % vertices.length];

            Raylib.draw_line_vector ({ start.x * PHYSICS_SCALE, start.y * PHYSICS_SCALE }, { end.x * PHYSICS_SCALE, end.y * PHYSICS_SCALE }, color);
        }
    }

    //  NOTE: This is from ChatGPT and very scuffed
    public static void draw_polygon_filled (Vector2[] vertices, Raylib.Color color) {
        Vector2 pivot = vertices[0];

        for (int i = vertices.length - 1; i > 1 ; i--) {
            Raylib.draw_triangle (
                { pivot.x * PHYSICS_SCALE, pivot.y * PHYSICS_SCALE },
                { vertices[i].x * PHYSICS_SCALE, vertices[i].y * PHYSICS_SCALE },
                { vertices[i - 1].x * PHYSICS_SCALE, vertices[i - 1].y * PHYSICS_SCALE },
                color
            );
        }
    }
}
