const rl = @import("raylib");

pub const Platform = struct {
    position: rl.Vector2,
    size: rl.Vector2,

    // Shared texture and frame definitions
    var texture: rl.Texture2D = undefined;
    // Size of each tile in the tilesheet
    const TILE_SIZE = 64;
    const frames = struct {
        // Platform tiles
        const left = rl.Rectangle{ .x = 0, .y = 64 * 2, .width = 64, .height = 64 };
        const middle = rl.Rectangle{ .x = 64, .y = 64 * 2, .width = 64, .height = 64 };
        const right = rl.Rectangle{ .x = 64 * 2, .y = 64 * 2, .width = 64, .height = 64 };
    };

    pub fn init() !void {
        Platform.texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformPack_tilesheet.png");
    }

    pub fn deinit() void {
        rl.unloadTexture(Platform.texture);
    }

    pub fn draw(self: Platform) void {
        const tiles_count = @as(i32, @intFromFloat(self.size.x / TILE_SIZE));

        // Draw left edge
        rl.drawTexturePro(
            Platform.texture,
            frames.left,
            .{
                .x = self.position.x,
                .y = self.position.y,
                .width = TILE_SIZE,
                .height = TILE_SIZE,
            },
            .{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );

        // Draw middle tiles
        var i: i32 = 1;
        while (i < tiles_count - 1) : (i += 1) {
            rl.drawTexturePro(
                Platform.texture,
                frames.middle,
                .{
                    .x = self.position.x + @as(f32, @floatFromInt(i)) * TILE_SIZE,
                    .y = self.position.y,
                    .width = TILE_SIZE,
                    .height = TILE_SIZE,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                rl.Color.white,
            );
        }

        // Draw right edge
        rl.drawTexturePro(
            Platform.texture,
            frames.right,
            .{
                .x = self.position.x + @as(f32, @floatFromInt(tiles_count - 1)) * TILE_SIZE,
                .y = self.position.y,
                .width = TILE_SIZE,
                .height = TILE_SIZE,
            },
            .{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );
    }
};

pub fn createPlatforms() [11]Platform {
    // TODO: tile editor
    return [_]Platform{
        // Starting platform
        .{ .position = .{ .x = 0, .y = 400 }, .size = .{ .x = 384, .y = 64 } },

        // First jump section
        .{ .position = .{ .x = 500, .y = 350 }, .size = .{ .x = 192, .y = 64 } },
        .{ .position = .{ .x = 800, .y = 300 }, .size = .{ .x = 192, .y = 64 } },

        // Rising stairs
        .{ .position = .{ .x = 1100, .y = 250 }, .size = .{ .x = 192, .y = 64 } },
        .{ .position = .{ .x = 1350, .y = 200 }, .size = .{ .x = 192, .y = 64 } },
        .{ .position = .{ .x = 1600, .y = 150 }, .size = .{ .x = 192, .y = 64 } },

        // High platform
        .{ .position = .{ .x = 1850, .y = 150 }, .size = .{ .x = 384, .y = 64 } },

        // Descending stairs
        .{ .position = .{ .x = 2350, .y = 200 }, .size = .{ .x = 192, .y = 64 } },
        .{ .position = .{ .x = 2600, .y = 250 }, .size = .{ .x = 192, .y = 64 } },
        .{ .position = .{ .x = 2850, .y = 300 }, .size = .{ .x = 192, .y = 64 } },

        // Ending platform
        .{ .position = .{ .x = 3100, .y = 400 }, .size = .{ .x = 384, .y = 64 } },
    };
}
