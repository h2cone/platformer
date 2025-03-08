const std = @import("std");
const rl = @import("raylib");
const Platform = @import("platform.zig").Platform;

// Define player states
pub const PlayerState = enum {
    Idle,
    Walk,
    Jump,
    Duck,
    Climb,
    Happy,
};

pub const Player = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: rl.Vector2,
    isJumping: bool,
    state: PlayerState,

    // Single texture for all states
    texture: rl.Texture2D,

    // Frame rectangles for each state
    frames: struct {
        idle: rl.Rectangle,
        walk1: rl.Rectangle,
        walk2: rl.Rectangle,
        jump: rl.Rectangle,
        duck: rl.Rectangle,
        climb1: rl.Rectangle,
        climb2: rl.Rectangle,
        happy: rl.Rectangle,
    },

    // For walk animation timing
    framesCounter: i32,

    // For flipping sprite based on direction
    isFlipped: bool,

    const MOVE_SPEED = 200.0;
    const JUMP_FORCE = -400.0;
    const GRAVITY = 800.0;
    const FRAME_SPEED = 30;

    // Character frame size in the tilesheet
    const FRAME_WIDTH = 96;
    const FRAME_HEIGHT = 96;

    pub fn init() !Player {
        // Load the tilesheet
        const texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformerPack_character.png");

        return Player{
            .position = .{ .x = 100, .y = 300 },
            .velocity = .{ .x = 0, .y = 0 },
            .size = .{ .x = 48, .y = 48 }, // Display size
            .isJumping = false,
            .state = PlayerState.Idle,
            .texture = texture,
            // Define frame rectangles for each state
            .frames = .{
                .idle = rl.Rectangle{ .x = 0, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .jump = rl.Rectangle{ .x = FRAME_WIDTH, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .walk1 = rl.Rectangle{ .x = FRAME_WIDTH * 2, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .walk2 = rl.Rectangle{ .x = FRAME_WIDTH * 3, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .climb1 = rl.Rectangle{ .x = FRAME_WIDTH * 4, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .climb2 = rl.Rectangle{ .x = FRAME_WIDTH * 5, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .duck = rl.Rectangle{ .x = FRAME_WIDTH * 6, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .happy = rl.Rectangle{ .x = FRAME_WIDTH * 7, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
            },
            .framesCounter = 0,
            .isFlipped = false,
        };
    }

    pub fn update(self: *Player, dt: f32, platforms: []const Platform) void {
        // Determine horizontal movement and update state
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            self.velocity.x = MOVE_SPEED;
            self.isFlipped = false;
            if (!self.isJumping) self.state = PlayerState.Walk;
        } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
            self.velocity.x = -MOVE_SPEED;
            self.isFlipped = true;
            if (!self.isJumping) self.state = PlayerState.Walk;
        } else {
            self.velocity.x = 0;
            if (!self.isJumping) self.state = PlayerState.Idle;
        }

        // Duck state if down key is pressed and not jumping
        if (rl.isKeyDown(rl.KeyboardKey.down) and !self.isJumping) {
            self.state = PlayerState.Duck;
        }

        // Jump
        if (rl.isKeyPressed(rl.KeyboardKey.space) and !self.isJumping) {
            self.velocity.y = JUMP_FORCE;
            self.isJumping = true;
            self.state = PlayerState.Jump;
        }

        // Apply gravity
        self.velocity.y += GRAVITY * dt;

        // Update position
        self.position.x += self.velocity.x * dt;
        self.position.y += self.velocity.y * dt;

        // Collision detection with platforms
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                if (self.velocity.y > 0) {
                    self.position.y = platform.position.y - self.size.y;
                    self.velocity.y = 0;
                    self.isJumping = false;
                    // Reset state to Idle if no horizontal input
                    if (self.velocity.x == 0) {
                        self.state = PlayerState.Idle;
                    } else {
                        self.state = PlayerState.Walk;
                    }
                }
            }
        }

        // Update walk animation if in Walk state
        if (self.state == PlayerState.Walk) {
            self.framesCounter += 1;
            if (self.framesCounter >= FRAME_SPEED) {
                // Toggle between walk1 and walk2 by using framesCounter mod 2
                self.framesCounter = 0;
            }
        } else {
            // Reset counter for non-walk states if needed
            self.framesCounter = 0;
        }
    }

    pub fn checkCollision(self: Player, platform: Platform) bool {
        return self.position.x < platform.position.x + platform.size.x and
            self.position.x + self.size.x > platform.position.x and
            self.position.y < platform.position.y + platform.size.y and
            self.position.y + self.size.y > platform.position.y;
    }

    pub fn draw(self: Player) void {
        var sourceRect = self.frames.idle;

        // Select source rectangle based on state
        switch (self.state) {
            PlayerState.Idle => {
                sourceRect = self.frames.idle;
            },
            PlayerState.Walk => {
                // Alternate between walk textures
                if (@rem(self.framesCounter, 2) == 0) {
                    sourceRect = self.frames.walk1;
                } else {
                    sourceRect = self.frames.walk2;
                }
            },
            PlayerState.Jump => {
                sourceRect = self.frames.jump;
            },
            PlayerState.Duck => {
                sourceRect = self.frames.duck;
            },
            PlayerState.Climb => {
                // For climb we can alternate between two climb textures
                if (@rem(self.framesCounter, 2) == 0) {
                    sourceRect = self.frames.climb1;
                } else {
                    sourceRect = self.frames.climb2;
                }
            },
            PlayerState.Happy => {
                sourceRect = self.frames.happy;
            },
        }

        // Apply flip if needed
        if (self.isFlipped) {
            sourceRect.width = -sourceRect.width;
        }

        // Destination rectangle (where to draw on screen)
        const dest = rl.Rectangle{
            .x = self.position.x,
            .y = self.position.y,
            .width = self.size.x,
            .height = self.size.y,
        };

        // Origin (rotation/scale origin point)
        const origin = rl.Vector2{ .x = 0, .y = 0 };

        // Draw the texture
        rl.drawTexturePro(self.texture, sourceRect, dest, origin, 0.0, rl.Color.white);
    }

    pub fn deinit(self: *Player) void {
        rl.unloadTexture(self.texture);
    }
};
