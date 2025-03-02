const std = @import("std");
const rl = @import("raylib");
const Platform = @import("platform.zig").Platform;

pub const Player = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: rl.Vector2,
    isJumping: bool,

    const MOVE_SPEED = 200.0;
    const JUMP_FORCE = -400.0;
    const GRAVITY = 800.0;

    pub fn init() Player {
        return Player{
            .position = .{ .x = 100, .y = 300 },
            .velocity = .{ .x = 0, .y = 0 },
            .size = .{ .x = 20, .y = 20 },
            .isJumping = false,
        };
    }

    pub fn update(self: *Player, dt: f32, platforms: []const Platform) void {
        // Horizontal movement
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            self.velocity.x = MOVE_SPEED;
        } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
            self.velocity.x = -MOVE_SPEED;
        } else {
            self.velocity.x = 0;
        }

        // Jump
        if (rl.isKeyPressed(rl.KeyboardKey.space) and !self.isJumping) {
            self.velocity.y = JUMP_FORCE;
            self.isJumping = true;
        }

        // Apply gravity
        self.velocity.y += GRAVITY * dt;

        // Update position
        self.position.x += self.velocity.x * dt;
        self.position.y += self.velocity.y * dt;

        // Collision detection
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                if (self.velocity.y > 0) {
                    self.position.y = platform.position.y - self.size.y;
                    self.velocity.y = 0;
                    self.isJumping = false;
                }
            }
        }
    }

    pub fn checkCollision(self: Player, platform: Platform) bool {
        return self.position.x < platform.position.x + platform.size.x and
            self.position.x + self.size.x > platform.position.x and
            self.position.y < platform.position.y + platform.size.y and
            self.position.y + self.size.y > platform.position.y;
    }

    pub fn draw(self: Player) void {
        const posX = @as(i32, @intFromFloat(self.position.x));
        const posY = @as(i32, @intFromFloat(self.position.y));
        const width = @as(i32, @intFromFloat(self.size.x));
        const height = @as(i32, @intFromFloat(self.size.y));
        rl.drawRectangle(posX, posY, width, height, rl.Color.white);
    }
};
