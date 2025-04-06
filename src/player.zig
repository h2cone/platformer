const std = @import("std");
const rl = @import("raylib");
const Platform = @import("platform.zig").Platform;

pub const State = enum {
    Idle,
    Walk,
    Jump,
    Slide,
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
        slide: rl.Rectangle,
    },
    framesCount: u8,
    isFlipped: bool,

    wallJumpDirection: i8,
    wallJumpCountdown: f32,

    const MOVE_SPEED = 200.0;
    const JUMP_FORCE = -500.0;
    const GRAVITY = 1000.0;

    const FRAME_SPEED = 15;
    const FRAME_WIDTH = 96;
    const FRAME_HEIGHT = 96;

    const PLAYER_WIDTH = 48;
    const PLAYER_HEIGHT = 48;

    const WALL_DETECTION_RANGE = PLAYER_WIDTH / 3;
    const WALL_SLIDE_SPEED = 100.0;
    const WALL_JUMP_BUFFER_TIME = 0.3;

    pub fn init(initial_position: rl.Vector2) !Player {
        const texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformerPack_character.png");
        return Player{
            .position = initial_position,
            .velocity = .{ .x = 0, .y = 0 },
            .size = .{ .x = PLAYER_WIDTH, .y = PLAYER_HEIGHT },
            .state = State.Idle,
            .texture = texture,
            .frames = .{
                .idle = rl.Rectangle{ .x = 0, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .jump = rl.Rectangle{ .x = FRAME_WIDTH * 1, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .walk1 = rl.Rectangle{ .x = FRAME_WIDTH * 2, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .walk2 = rl.Rectangle{ .x = FRAME_WIDTH * 3, .y = 0, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
                .slide = rl.Rectangle{ .x = FRAME_WIDTH * 2, .y = FRAME_HEIGHT * 1, .width = FRAME_WIDTH, .height = FRAME_HEIGHT },
            },
            .framesCount = 0,
            .isFlipped = false,
            .wallJumpDirection = 0,
            .wallJumpCountdown = 0,
        };
    }

    pub fn update(self: *Player, dt: f32, platforms: []Platform) void {
        // Apply gravity
        self.velocity.y += GRAVITY * dt;
        switch (self.state) {
            State.Idle => {
                if (rl.isKeyDown(rl.KeyboardKey.right)) {
                    self.velocity.x = MOVE_SPEED;
                    self.isFlipped = false;
                    self.state = State.Walk;
                } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
                    self.velocity.x = -MOVE_SPEED;
                    self.isFlipped = true;
                    self.state = State.Walk;
                } else if (rl.isKeyPressed(rl.KeyboardKey.space)) {
                    self.velocity.y = JUMP_FORCE;
                    self.state = State.Jump;
                }
            },
            State.Walk => {
                if (rl.isKeyDown(rl.KeyboardKey.right)) {
                    self.velocity.x = MOVE_SPEED;
                    self.isFlipped = false;
                    self.state = State.Walk;
                } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
                    self.velocity.x = -MOVE_SPEED;
                    self.isFlipped = true;
                    self.state = State.Walk;
                } else {
                    self.velocity.x = 0;
                    self.state = State.Idle;
                }
                if (rl.isKeyPressed(rl.KeyboardKey.space)) {
                    self.velocity.y = JUMP_FORCE;
                    self.state = State.Jump;
                }
            },
            State.Jump => {
                self.updateWallJumpDirection(platforms);
                if (self.wallJumpDirection == 0) {
                    if (rl.isKeyDown(rl.KeyboardKey.right)) {
                        self.velocity.x = MOVE_SPEED;
                        self.isFlipped = false;
                    } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
                        self.velocity.x = -MOVE_SPEED;
                        self.isFlipped = true;
                    }
                } else {
                    if (self.velocity.y > WALL_SLIDE_SPEED) {
                        self.velocity.y = WALL_SLIDE_SPEED;
                    }
                    self.state = State.Slide;
                }
            },
            State.Slide => {
                if (self.velocity.y > 0) {
                    if (self.wallJumpCountdown > 0) {
                        self.wallJumpCountdown -= dt;
                    }
                    if (rl.isKeyPressed(rl.KeyboardKey.space)) {
                        std.debug.print("{} Prepare to wall jump\n", .{std.time.timestamp()});
                        self.wallJumpCountdown = WALL_JUMP_BUFFER_TIME;
                    }
                    if (self.wallJumpCountdown > 0) {
                        // TODO Wall jump
                        self.wallJumpDirection = 0;
                    }
                } else {
                    self.wallJumpDirection = 0;
                }
            },
        }
        // Use the old position to detect collisions, because updating the position first and then correcting it when a collision is detected
        const oldPosition = self.position;
        self.position.x += self.velocity.x * dt;
        // Detect horizontal collisions
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                if (oldPosition.x + self.size.x <= platform.position.x) {
                    // Player is on left side of the platform
                    self.position.x = platform.position.x - self.size.x;
                } else if (oldPosition.x >= platform.position.x + platform.size.x) {
                    // Player is on right side of the platform
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
                    // Player is on top of the platform
                    self.position.y = platform.position.y - self.size.y;
                    // Reset state when landing
                    if (self.state == State.Jump or self.state == State.Slide) {
                        if (self.velocity.x == 0) {
                            self.state = State.Idle;
                        } else {
                            self.state = State.Walk;
                        }
                    }
                } else if (oldPosition.y >= platform.position.y + platform.size.y) {
                    // Player is on bottom of the platform
                    self.position.y = platform.position.y + platform.size.y;
                }
                self.velocity.y = 0;
            }
        }
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

    fn updateWallJumpDirection(self: *Player, platforms: []Platform) void {
        for (platforms) |platform| {
            // Detect left wall
            if (self.position.x <= platform.position.x + platform.size.x and
                self.position.x > platform.position.x + platform.size.x - WALL_DETECTION_RANGE and
                self.position.y + self.size.y > platform.position.y and
                self.position.y < platform.position.y + platform.size.y)
            {
                self.wallJumpDirection = 1;
                break;
            }
            // Detect right wall
            if (self.position.x + self.size.x >= platform.position.x and
                self.position.x + self.size.x < platform.position.x + WALL_DETECTION_RANGE and
                self.position.y + self.size.y > platform.position.y and
                self.position.y < platform.position.y + platform.size.y)
            {
                self.wallJumpDirection = -1;
                break;
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
            State.Slide => {
                sourceRect = self.frames.slide;
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
