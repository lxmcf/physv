namespace Physv {
    public struct Vector2 {
        public const Vector2 ZERO = { 0.0f, 0.0f };
        public const Vector2 ONE = { 1.0f, 1.0f };
        public const Vector2 MIN = { float.MIN, float.MIN };
        public const Vector2 MAX = { float.MAX, float.MAX };

        public float x;
        public float y;

        public inline static float length_squared (Vector2 vector) {
            return (vector.x * vector.x) + (vector.y * vector.y);
        }

        public inline static float length (Vector2 vector) {
            return Math.sqrtf (Vector2.length_squared (vector));
        }

        public inline static Vector2 abs (Vector2 vector) {
            return {
                Math.fabsf (vector.x),
                Math.fabsf (vector.y)
            };
        }

        public inline static Vector2 normalise (Vector2 vector) {
            float length = Vector2.length (vector);

            return {
                vector.x / length,
                vector.y / length
            };
        }

        public inline static float cross (Vector2 vector1, Vector2 vector2) {
            return (vector1.x * vector2.y) + (vector1.y * vector2.x);
        }

        public inline static Vector2 transform (Vector2 vector, Transform transform) {
            float rotation_x = (transform.cos * vector.x) - (transform.sin * vector.y);
            float rotation_y = (transform.sin * vector.x) + (transform.cos * vector.y);

            return { rotation_x + transform.position_x, rotation_y + transform.position_y };
        }

        //----------------------------------------------------------------------------------
        // Vector based manipulation
        //----------------------------------------------------------------------------------

        public inline static Vector2 add (Vector2 vector1, Vector2 vector2) {
            return {
                vector1.x += vector2.x,
                vector1.y += vector2.y
            };
        }

        public inline static Vector2 subtract (Vector2 vector1, Vector2 vector2) {
            return {
                vector1.x -= vector2.x,
                vector1.y -= vector2.y
            };
        }

        public inline static Vector2 multiply (Vector2 vector1, Vector2 vector2) {
            return {
                vector1.x *= vector2.x,
                vector1.y *= vector2.y
            };
        }

        public inline static Vector2 divide (Vector2 vector1, Vector2 vector2) {
            return {
                vector1.x /= vector2.x,
                vector1.y /= vector2.y
            };
        }

        //----------------------------------------------------------------------------------
        // Value based manipulation
        //----------------------------------------------------------------------------------

        public inline static Vector2 add_value (Vector2 vector, float value) {
            return {
                vector.x += value,
                vector.y += value
            };
        }

        public inline static Vector2 subtract_value (Vector2 vector1, float value) {
            return {
                vector1.x -= value,
                vector1.y -= value
            };
        }

        public inline static Vector2 multiply_value (Vector2 vector1, float value) {
            return {
                vector1.x *= value,
                vector1.y *= value
            };
        }

        public inline static Vector2 divide_value (Vector2 vector1, float value) {
            return {
                vector1.x /= value,
                vector1.y /= value
            };
        }

        //----------------------------------------------------------------------------------
        // Vector based math
        //----------------------------------------------------------------------------------
        public inline static float dot (Vector2 vector1, Vector2 vector2) {
            return (vector1.x * vector2.x) + (vector1.y * vector2.y);
        }

        public inline static bool equals_rough (Vector2 vector1, Vector2 vector2) {
            float margin = 0.0005f;

            return (distance_squared (vector1, vector2) < (margin * margin));
        }

        public inline static bool equals (Vector2 vector1, Vector2 vector2) {
            return (vector1.x == vector2.x && vector1.y == vector2.y);
        }

        public inline static float distance_squared (Vector2 vector1, Vector2 vector2) {
            float direction_x = vector1.x - vector2.x;
            float direction_y = vector1.y - vector2.y;

            return (direction_x * direction_x) + (direction_y * direction_y);
        }

        public inline static float distance (Vector2 vector1, Vector2 vector2) {
            return Math.sqrtf (distance_squared (vector1, vector2));
        }
    }
}
