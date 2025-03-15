const std = @import("std");
const rl = @import("raylib");
const Player = @import("player.zig").Player;
const platform_mod = @import("platform.zig");
const Platform = platform_mod.Platform;

pub const Game = struct {
    player: Player,
    camera: rl.Camera2D,
    platforms: []Platform,
    alloc: std.mem.Allocator,

    pub fn init(width: i32, height: i32, alloc: std.mem.Allocator) !Game {
        // Load platforms first
        try Platform.init();
        const platforms = try platform_mod.buildPlatforms("./assets/land.tmj", alloc);

        // Calculate initial player position based on the first platform
        const init_player_pos = rl.Vector2{
            // A bit offset from the left edge
            .x = platforms[0].position.x + 48.0,
            // Place on top of the platform
            .y = platforms[0].position.y - 48.0,
        };

        const player = try Player.init(init_player_pos);

        const camera = rl.Camera2D{
            .offset = .{ .x = @as(f32, @floatFromInt(width)) / 2.0, .y = @as(f32, @floatFromInt(height)) / 2.0 },
            .target = .{ .x = player.position.x, .y = player.position.y },
            .rotation = 0.0,
            .zoom = 1.0,
        };

        return Game{
            .player = player,
            .camera = camera,
            .platforms = platforms,
            .alloc = alloc,
        };
    }

    pub fn update(self: *Game) void {
        const dt = rl.getFrameTime();
        self.player.update(dt, self.platforms);

        // Update camera position to follow player
        self.camera.target = .{
            .x = self.player.position.x + self.player.size.x / 2.0,
            .y = self.player.position.y + self.player.size.y / 2.0,
        };
    }

    pub fn draw(self: Game) void {
        rl.clearBackground(rl.Color.black);

        // Begin 2D mode drawing (with camera)
        rl.beginMode2D(self.camera);

        // Draw platforms
        for (self.platforms) |platform| {
            platform.draw();
        }

        // Draw player
        self.player.draw();

        rl.endMode2D();
    }

    pub fn deinit(self: *Game) void {
        self.player.deinit();
        // Cleanup platform texture
        Platform.deinit();
        // Free the platform array memory
        self.alloc.free(self.platforms);
    }
};
