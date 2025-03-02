const rl = @import("raylib");

pub const Platform = struct {
    position: rl.Vector2,
    size: rl.Vector2,

    pub fn draw(self: Platform) void {
        const posX = @as(i32, @intFromFloat(self.position.x));
        const posY = @as(i32, @intFromFloat(self.position.y));
        const width = @as(i32, @intFromFloat(self.size.x));
        const height = @as(i32, @intFromFloat(self.size.y));
        rl.drawRectangle(posX, posY, width, height, rl.Color.purple);
    }
};

pub fn createPlatforms() [11]Platform {
    return [_]Platform{
        // Starting platform
        .{ .position = .{ .x = 0, .y = 400 }, .size = .{ .x = 400, .y = 20 } },

        // First jump section
        .{ .position = .{ .x = 500, .y = 350 }, .size = .{ .x = 200, .y = 20 } },
        .{ .position = .{ .x = 800, .y = 300 }, .size = .{ .x = 200, .y = 20 } },

        // Rising stairs
        .{ .position = .{ .x = 1100, .y = 250 }, .size = .{ .x = 150, .y = 20 } },
        .{ .position = .{ .x = 1350, .y = 200 }, .size = .{ .x = 150, .y = 20 } },
        .{ .position = .{ .x = 1600, .y = 150 }, .size = .{ .x = 150, .y = 20 } },

        // High platform
        .{ .position = .{ .x = 1850, .y = 150 }, .size = .{ .x = 400, .y = 20 } },

        // Descending stairs
        .{ .position = .{ .x = 2350, .y = 200 }, .size = .{ .x = 150, .y = 20 } },
        .{ .position = .{ .x = 2600, .y = 250 }, .size = .{ .x = 150, .y = 20 } },
        .{ .position = .{ .x = 2850, .y = 300 }, .size = .{ .x = 150, .y = 20 } },

        // Ending platform
        .{ .position = .{ .x = 3100, .y = 400 }, .size = .{ .x = 400, .y = 20 } },
    };
}
