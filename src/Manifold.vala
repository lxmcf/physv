namespace Physv {
    public struct Manifold {
        public unowned PhysicsBody body1;
        public unowned PhysicsBody body2;

        public Vector2 normal;
        public float depth;

        public Vector2 contact1;
        public Vector2 contact2;

        public int contact_count;
    }
}
