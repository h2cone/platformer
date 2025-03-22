const std = @import("std");
const rl = @import("raylib");
const Platform = @import("platform.zig").Platform;

pub const State = enum {
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
    state: State,
    texture: rl.Texture2D,
    // Animation frames
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
    framesCount: i32,
    isFlipped: bool,

    const MOVE_SPEED = 200.0;
    const JUMP_FORCE = -500.0;
    const GRAVITY = 800.0;
    const AIR_RESISTANCE = 1;
    const FRAME_SPEED = 15;
    const FRAME_WIDTH = 96;
    const FRAME_HEIGHT = 96;

    pub fn init(initial_position: rl.Vector2) !Player {
        const texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformerPack_character.png");
        return Player{
            .position = initial_position,
            .velocity = .{ .x = 0, .y = 0 },
            .size = .{ .x = 48, .y = 48 },
            .state = State.Idle,
            .texture = texture,
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
            .framesCount = 0,
            .isFlipped = false,
        };
    }

    pub fn update(self: *Player, dt: f32, platforms: []const Platform) void {
        // Movement
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            self.velocity.x = MOVE_SPEED;
            self.isFlipped = false;
            if (self.state != State.Jump and self.state != State.Climb) self.state = State.Walk;
        } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
            self.velocity.x = -MOVE_SPEED;
            self.isFlipped = true;
            if (self.state != State.Jump and self.state != State.Climb) self.state = State.Walk;
        } else {
            if (self.state == State.Jump) {
                self.velocity.x *= AIR_RESISTANCE;
            } else {
                self.velocity.x = 0;
                self.state = State.Idle;
            }
        }
        // Duck state if down key is pressed and not jumping
        if (rl.isKeyDown(rl.KeyboardKey.down) and self.state != State.Jump) {
            self.state = State.Duck;
        }
        // Jump
        if (rl.isKeyPressed(rl.KeyboardKey.space) and self.state != State.Jump) {
            self.velocity.y = JUMP_FORCE;
            self.state = State.Jump;
        }
        // Apply gravity
        self.velocity.y += GRAVITY * dt;
        // Update position
        updatePosition(self, dt, platforms);
        // Update walk animation if in Walk state
        if (self.state == State.Walk) {
            self.framesCount += 1;
            if (self.framesCount >= FRAME_SPEED) {
                self.framesCount = 0;
            }
        } else {
            self.framesCount = 0;
        }
    }

    fn updatePosition(self: *Player, dt: f32, platforms: []const Platform) void {
        const oldPosition = self.position;
        self.position.x += self.velocity.x * dt;
        // Detect horizontal collisions
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                if (oldPosition.x + self.size.x <= platform.position.x) {
                    self.position.x = platform.position.x - self.size.x;
                } else if (oldPosition.x >= platform.position.x + platform.size.x) {
                    self.position.x = platform.position.x + platform.size.x;
                }
                self.velocity.x = 0;
            }
        }
        self.position.y += self.velocity.y * dt;
        // Detect vertical collisions
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                if (oldPosition.y + self.size.y <= platform.position.y) {
                    self.position.y = platform.position.y - self.size.y;
                    // Reset state when landing
                    if (self.state == State.Jump) {
                        if (self.velocity.x == 0) {
                            self.state = State.Idle;
                        } else {
                            self.state = State.Walk;
                        }
                    }
                } else if (oldPosition.y >= platform.position.y + platform.size.y) {
                    self.position.y = platform.position.y + platform.size.y;
                }
                self.velocity.y = 0;
            }
        }
    }

    fn checkCollision(self: Player, platform: Platform) bool {
        return self.position.x < platform.position.x + platform.size.x and
            self.position.x + self.size.x > platform.position.x and
            self.position.y < platform.position.y + platform.size.y and
            self.position.y + self.size.y > platform.position.y;
    }

    pub fn draw(self: Player) void {
        var sourceRect = self.frames.idle;
        // Select source rectangle based on state
        switch (self.state) {
            State.Idle => {
                sourceRect = self.frames.idle;
            },
            State.Walk => {
                // Alternate between walk textures
                if (@rem(self.framesCount, 2) == 0) {
                    sourceRect = self.frames.walk1;
                } else {
                    sourceRect = self.frames.walk2;
                }
            },
            State.Jump => {
                sourceRect = self.frames.jump;
            },
            State.Duck => {
                sourceRect = self.frames.duck;
            },
            State.Climb => {
                // For climb we can alternate between two climb textures
                if (@rem(self.framesCount, 2) == 0) {
                    sourceRect = self.frames.climb1;
                } else {
                    sourceRect = self.frames.climb2;
                }
            },
            State.Happy => {
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
