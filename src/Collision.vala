namespace Physv {
    public static bool intersec_circles (Vector2 circle1, float radius1, Vector2 circle2, float radius2, out Vector2 normal, out float depth) {
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
