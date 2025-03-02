const std = @import("std");
const rl = @import("raylib");
const Game = @import("game.zig").Game;

pub fn main() !void {
    // Initialization
    const win_width = 800;
    const win_height = 450;

    rl.initWindow(win_width, win_height, "Platformer");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var game = Game.init(win_width, win_height);

    // Main game loop
    while (!rl.windowShouldClose()) {
        game.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        game.draw();
    }
}
