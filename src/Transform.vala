namespace Physv {
    public struct Transform {
        public float position_x;
        public float position_y;

        public float sin;
        public float cos;

        public Transform (Vector2 position, float angle) {
            position_x = position.x;
            position_y = position.y;

            sin = Math.sinf (angle);
            cos = Math.cosf (angle);
        }
    }
}
