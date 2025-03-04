const std = @import("std");
const rl = @import("raylib");
const Player = @import("player.zig").Player;
const platform_mod = @import("platform.zig");
const Platform = platform_mod.Platform;

pub const Game = struct {
    player: Player,
    camera: rl.Camera2D,
    platforms: [11]Platform,

    pub fn init(win_width: i32, win_height: i32) !Game {
        const player = try Player.init();
        const camera = rl.Camera2D{
            .offset = .{ .x = @as(f32, @floatFromInt(win_width)) / 2.0, .y = @as(f32, @floatFromInt(win_height)) / 2.0 },
            .target = .{ .x = player.position.x, .y = player.position.y },
            .rotation = 0.0,
            .zoom = 1.0,
        };

        return Game{
            .player = player,
            .camera = camera,
            .platforms = platform_mod.createPlatforms(),
        };
    }

    pub fn update(self: *Game) void {
        const dt = rl.getFrameTime();
        self.player.update(dt, &self.platforms);

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
    }
};
