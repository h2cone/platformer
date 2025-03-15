const std = @import("std");
const rl = @import("raylib");
const Game = @import("game.zig").Game;

pub fn main() !void {
    // Initialize window
    const width = 800;
    const height = 450;
    rl.initWindow(width, height, "Platformer");
    defer rl.closeWindow();

    // Set target FPS
    rl.setTargetFPS(60);

    // Create a general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // Initialize game
    var game = Game.init(width, height, alloc) catch {
        std.debug.print("Failed to initialize game\n", .{});
        return;
    };
    defer game.deinit();

    // Game loop
    while (!rl.windowShouldClose()) {
        game.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        game.draw();
    }
}
