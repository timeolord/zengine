const sti = @import("sti");

const rl = @import("raylib");

const render = @import("render.zig");

pub const CameraSettings = struct {
    const lerp_time_ns: u64 = 200_000_000;
    const height_multiplier: f32 = 1.5;
    const fovy: f32 = 45;
    const projection: rl.CameraProjection = .perspective;
};

pub const CameraPosition = union(enum) {
    static: render.WorldPosition,
    lerp: struct {
        from: render.WorldPosition,
        to: render.WorldPosition,
        t: f64,
    },

    pub fn current(self: CameraPosition) render.WorldPosition {
        switch (self) {
            .static => |pos| return pos,
            .lerp => |l| return render.lerp3d(l.from, l.to, l.t),
        }
    }

    pub fn set_target(self: *CameraPosition, target: render.WorldPosition) void {
        const from = self.current();
        self.* = .{ .lerp = .{ .from = from, .to = target, .t = 0 } };
    }

    pub fn advance(self: *CameraPosition, dt: u64) void {
        switch (self.*) {
            .static => {},
            .lerp => |*l| {
                const dt_float: f64 = @floatFromInt(dt);
                const lerp_time: f64 = @floatFromInt(CameraSettings.lerp_time_ns);
                l.t = @min(l.t + dt_float / lerp_time, 1.0);
                if (l.t >= 1.0) {
                    self.* = .{ .static = l.to };
                }
            },
        }
    }
};

pub const Camera = struct {
    const Self = @This();

    position: CameraPosition,
    rotation: f32,
    zoom: f32,

    pub const default: Self = .{
        .position = .{ .static = .{ .data = .{ .x = 0, .y = 0, .z = 0 } } },
        .rotation = sti.math.pi / 2.0,
        .zoom = 7,
    };

    pub fn set_target(self: *Self, target: render.WorldPosition) void {
        self.position.set_target(target);
    }

    pub fn process(self: *Self, dt: u64) void {
        self.position.advance(dt);
    }

    pub fn current_position(self: Self) render.WorldPosition {
        return self.position.current();
    }

    pub fn to_rl_camera(self: Self) rl.Camera {
        const focus = self.current_position().data;
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
