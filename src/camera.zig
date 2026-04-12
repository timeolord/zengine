const sti = @import("sti");
const rl = @import("raylib");

pub const CameraSettings = struct {
    pub const lerp_time_ns: u64 = 200_000_000;
    pub const height_multiplier: f32 = 1.5;
    pub const fovy: f32 = 45;
    pub const projection: rl.CameraProjection = .perspective;
};

pub const CameraPosition = union(enum) {
    static: rl.Vector3,
    lerp: struct {
        from: rl.Vector3,
        to: rl.Vector3,
        t: f64,
    },

    pub fn current(self: CameraPosition) rl.Vector3 {
        return switch (self) {
            .static => |position| position,
            .lerp => |value| .{
                .x = @floatCast(value.from.x + (value.to.x - value.from.x) * value.t),
                .y = @floatCast(value.from.y + (value.to.y - value.from.y) * value.t),
                .z = @floatCast(value.from.z + (value.to.z - value.from.z) * value.t),
            },
        };
    }

    pub fn set_target(self: *CameraPosition, target: rl.Vector3) void {
        self.* = .{
            .lerp = .{
                .from = self.current(),
                .to = target,
                .t = 0,
            },
        };
    }

    pub fn advance(self: *CameraPosition, dt: u64) void {
        switch (self.*) {
            .static => {},
            .lerp => |*value| {
                const dt_float: f64 = @floatFromInt(dt);
                const lerp_time: f64 = @floatFromInt(CameraSettings.lerp_time_ns);
                value.t = @min(value.t + dt_float / lerp_time, 1.0);
                if (value.t >= 1.0) {
                    self.* = .{ .static = value.to };
                }
            },
        }
    }
};

pub const Camera = struct {
    position: CameraPosition,
    rotation: f32,
    zoom: f32,

    pub const default: Camera = .{
        .position = .{ .static = .{ .x = 0, .y = 0, .z = 0 } },
        .rotation = sti.math.pi / 2.0,
        .zoom = 7,
    };

    pub fn set_target(self: *Camera, target: rl.Vector3) void {
        self.position.set_target(target);
    }

    pub fn process(self: *Camera, dt: u64) void {
        self.position.advance(dt);
    }

    pub fn current_position(self: Camera) rl.Vector3 {
        return self.position.current();
    }

    pub fn to_rl_camera(self: Camera) rl.Camera3D {
        const focus = self.current_position();
        return .{
            .target = focus,
            .position = .{
                .x = focus.x + self.zoom * @cos(self.rotation),
                .y = focus.y + self.zoom * CameraSettings.height_multiplier,
                .z = focus.z + self.zoom * @sin(self.rotation),
            },
            .up = .{ .x = 0, .y = 1, .z = 0 },
            .fovy = CameraSettings.fovy,
            .projection = CameraSettings.projection,
        };
    }
};
