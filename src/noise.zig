pub fn Perlin(comptime T: type, scale: T) type {
    comptime switch (@typeInfo(T)) {
        .float => {},
        else => @compileError("expected a float type"),
    };

    return struct {
        const permutation = [256]u8{
            151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
            140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
            247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
            57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
            74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122,
            60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
            65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
            200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
            52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
            207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
            119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
            129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
            218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
            81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157,
            184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
            222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180,
        };

        fn fade(value: T) T {
            return value * value * value * (value * (value * 6.0 - 15.0) + 10.0);
        }

        fn lerp(t: T, a: T, b: T) T {
            return a + t * (b - a);
        }

        fn grad(hash: u8, x: T, y: T, z: T) T {
            return switch (hash & 15) {
                0, 12 => x + y,
                1, 14 => y - x,
                2 => x - y,
                3 => -x - y,
                4 => x + z,
                5 => z - x,
                6 => x - z,
                7 => -x - z,
                8 => y + z,
                9, 13 => z - y,
                10 => y - z,
                else => -y - z,
            };
        }

        pub fn generate(x_index: i32, z_index: i32) T {
            const x = @as(T, @floatFromInt(x_index)) * scale;
            const y = @as(T, 0);
            const z = @as(T, @floatFromInt(z_index)) * scale;

            const x_i: u8 = @truncate(@as(usize, @bitCast(@as(isize, @intFromFloat(@floor(x))))));
            const y_i: u8 = 0;
            const z_i: u8 = @truncate(@as(usize, @bitCast(@as(isize, @intFromFloat(@floor(z))))));

            const x_r = x - @floor(x);
            const y_r = y - @floor(y);
            const z_r = z - @floor(z);

            const u = fade(x_r);
            const v = fade(y_r);
            const w = fade(z_r);

            const a = permutation[x_i] +% y_i;
            const aa = permutation[a] +% z_i;
            const ab = permutation[a +% 1] +% z_i;
            const b = permutation[x_i +% 1] +% y_i;
            const ba = permutation[b] +% z_i;
            const bb = permutation[b +% 1] +% z_i;

            return lerp(
                w,
                lerp(
                    v,
                    lerp(u, grad(permutation[aa], x_r, y_r, z_r), grad(permutation[ba], x_r - 1.0, y_r, z_r)),
                    lerp(u, grad(permutation[ab], x_r, y_r - 1.0, z_r), grad(permutation[bb], x_r - 1.0, y_r - 1.0, z_r)),
                ),
                lerp(
                    v,
                    lerp(u, grad(permutation[aa +% 1], x_r, y_r, z_r - 1.0), grad(permutation[ba +% 1], x_r - 1.0, y_r, z_r - 1.0)),
                    lerp(u, grad(permutation[ab +% 1], x_r, y_r - 1.0, z_r - 1.0), grad(permutation[bb +% 1], x_r - 1.0, y_r - 1.0, z_r - 1.0)),
                ),
            );
        }
    };
}
