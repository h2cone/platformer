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

    // Textures for various actions
    texture_idle: rl.Texture2D,
    texture_walk1: rl.Texture2D,
    texture_walk2: rl.Texture2D,
    texture_jump: rl.Texture2D,
    texture_duck: rl.Texture2D,
    texture_climb1: rl.Texture2D,
    texture_climb2: rl.Texture2D,
    texture_happy: rl.Texture2D,

    // For walk animation timing
    framesCounter: i32,

    // For flipping sprite based on direction
    isFlipped: bool,

    const MOVE_SPEED = 200.0;
    const JUMP_FORCE = -400.0;
    const GRAVITY = 800.0;
    const FRAME_SPEED = 30;

    pub fn init() !Player {
        const charactersDir = "./assets/kenney_simplified-platformer-pack/PNG/Characters";
        // Load textures from assets
        const tex_idle = try rl.loadTexture(charactersDir ++ "/platformChar_idle.png");
        const tex_walk1 = try rl.loadTexture(charactersDir ++ "/platformChar_walk1.png");
        const tex_walk2 = try rl.loadTexture(charactersDir ++ "/platformChar_walk2.png");
        const tex_jump = try rl.loadTexture(charactersDir ++ "/platformChar_jump.png");
        const tex_duck = try rl.loadTexture(charactersDir ++ "/platformChar_duck.png");
        const tex_climb1 = try rl.loadTexture(charactersDir ++ "/platformChar_climb1.png");
        const tex_climb2 = try rl.loadTexture(charactersDir ++ "/platformChar_climb2.png");
        const tex_happy = try rl.loadTexture(charactersDir ++ "/platformChar_happy.png");

        return Player{
            .position = .{ .x = 100, .y = 300 },
            .velocity = .{ .x = 0, .y = 0 },
            // Adjust size if needed; here we assume 32x32
            .size = .{ .x = 32, .y = 32 },
            .isJumping = false,
            .state = PlayerState.Idle,
            .texture_idle = tex_idle,
            .texture_walk1 = tex_walk1,
            .texture_walk2 = tex_walk2,
            .texture_jump = tex_jump,
            .texture_duck = tex_duck,
            .texture_climb1 = tex_climb1,
            .texture_climb2 = tex_climb2,
            .texture_happy = tex_happy,
            .framesCounter = 0,
            .isFlipped = false,
        };
    }

    pub fn deinit(self: *Player) void {
        rl.unloadTexture(self.texture_idle);
        rl.unloadTexture(self.texture_walk1);
        rl.unloadTexture(self.texture_walk2);
        rl.unloadTexture(self.texture_jump);
        rl.unloadTexture(self.texture_duck);
        rl.unloadTexture(self.texture_climb1);
        rl.unloadTexture(self.texture_climb2);
        rl.unloadTexture(self.texture_happy);
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
        var tex: rl.Texture2D = self.texture_idle; // default

        // Select texture based on state
        switch (self.state) {
            PlayerState.Idle => {
                tex = self.texture_idle;
            },
            PlayerState.Walk => {
                // Alternate between walk textures
                if (@rem(self.framesCounter, 2) == 0) {
                    tex = self.texture_walk1;
                } else {
                    tex = self.texture_walk2;
                }
            },
            PlayerState.Jump => {
                tex = self.texture_jump;
            },
            PlayerState.Duck => {
                tex = self.texture_duck;
            },
            PlayerState.Climb => {
                // For climb we can alternate between two climb textures
                if (@rem(self.framesCounter, 2) == 0) {
                    tex = self.texture_climb1;
                } else {
                    tex = self.texture_climb2;
                }
            },
            PlayerState.Happy => {
                tex = self.texture_happy;
            },
        }

        // Source rectangle (entire texture)
        const source = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = if (self.isFlipped) -@as(f32, @floatFromInt(tex.width)) else @as(f32, @floatFromInt(tex.width)),
            .height = @as(f32, @floatFromInt(tex.height)),
        };

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
        rl.drawTexturePro(tex, source, dest, origin, 0.0, rl.Color.white);
    }
};
