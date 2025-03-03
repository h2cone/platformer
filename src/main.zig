const std = @import("std");
const rl = @import("raylib");
const Game = @import("game.zig").Game;

pub fn main() !void {
    // Initialization
    const winWidth = 800;
    const winHeight = 450;

    rl.initWindow(winWidth, winHeight, "Platformer");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var game = Game.init(winWidth, winHeight) catch {
        std.log.err("Failed to initialize game", .{});
        return;
    };

    // Main game loop
    while (!rl.windowShouldClose()) {
        game.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        game.draw();
    }
}
