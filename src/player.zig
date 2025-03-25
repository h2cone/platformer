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
    WallSlide,
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

    isTouchingWall: bool,
    wallDirection: f32,
    // Wall detection tolerance: can still wall jump after leaving the wall
    wallJumpBufferTime: f32,
    oppositeKeyPressed: bool,
    // Key press tolerance: no need to press the arrow keys and jump button perfectly at the same time
    oppositeKeyBufferTime: f32,
    lastWallJumpDirection: f32,
    reachedApex: bool,

    const MOVE_SPEED = 200.0;
    const JUMP_FORCE = -500.0;
    const GRAVITY = 1000.0;
    const AIR_RESISTANCE = 1;
    const FRAME_SPEED = 15;
    const FRAME_WIDTH = 96;
    const FRAME_HEIGHT = 96;

    const WALL_SLIDE_SPEED = 100.0;
    const WALL_JUMP_FORCE_X = 350.0;
    const WALL_JUMP_FORCE_Y = -500.0;
    const WALL_JUMP_BUFFER_TIME = 0.3;
    const OPPOSITE_KEY_BUFFER_TIME = 0.15;
    const WALL_DETECTION_RANGE = 15.0;

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
            .isTouchingWall = false,
            .wallDirection = 0,
            .wallJumpBufferTime = 0,
            .oppositeKeyPressed = false,
            .oppositeKeyBufferTime = 0,
            .lastWallJumpDirection = 0,
            .reachedApex = false,
        };
    }

    pub fn update(self: *Player, dt: f32, platforms: []const Platform) void {
        self.updateWallSlideState(platforms);

        if (!self.reachedApex and self.velocity.y >= 0) {
            self.reachedApex = true;
        }

        if (self.state != State.Jump and self.state != State.WallSlide) {
            self.lastWallJumpDirection = 0;
            self.reachedApex = false;
        }

        if (self.wallJumpBufferTime > 0) {
            self.wallJumpBufferTime -= dt;
        }

        if (self.oppositeKeyBufferTime > 0) {
            self.oppositeKeyBufferTime -= dt;
        }

        if ((self.wallDirection == -1 and rl.isKeyDown(rl.KeyboardKey.right)) or
            (self.wallDirection == 1 and rl.isKeyDown(rl.KeyboardKey.left)))
        {
            self.oppositeKeyPressed = true;
            self.oppositeKeyBufferTime = OPPOSITE_KEY_BUFFER_TIME;
        }

        if (self.isTouchingWall) {
            if (self.wallDirection == self.lastWallJumpDirection and
                !self.reachedApex)
            {
                self.isTouchingWall = false;
                self.state = State.Jump;
            } else {
                self.wallJumpBufferTime = WALL_JUMP_BUFFER_TIME;
            }
        }

        if ((self.isTouchingWall or self.wallJumpBufferTime > 0) and
            (self.oppositeKeyPressed or self.oppositeKeyBufferTime > 0))
        {
            if (rl.isKeyPressed(rl.KeyboardKey.space)) {
                self.lastWallJumpDirection = self.wallDirection;
                self.reachedApex = false;

                self.velocity.x = WALL_JUMP_FORCE_X * -self.wallDirection;
                self.velocity.y = WALL_JUMP_FORCE_Y;
                self.state = State.Jump;
                self.isTouchingWall = false;
                self.wallDirection = 0;
                self.wallJumpBufferTime = 0;
                self.oppositeKeyPressed = false;
                self.oppositeKeyBufferTime = 0;

                self.isFlipped = self.velocity.x < 0;

                self.position.y += self.velocity.y * dt;
                self.position.x += self.velocity.x * dt;

                updatePosition(self, 0, platforms);
                return;
            }
        }

        var allowLeftMovement = true;
        var allowRightMovement = true;

        if (!self.reachedApex and self.lastWallJumpDirection != 0) {
            if (self.lastWallJumpDirection > 0) {
                allowRightMovement = false;
            } else if (self.lastWallJumpDirection < 0) {
                allowLeftMovement = false;
            }
        }

        if (rl.isKeyDown(rl.KeyboardKey.right) and allowRightMovement) {
            self.velocity.x = MOVE_SPEED;
            self.isFlipped = false;
            if (self.state != State.Jump and self.state != State.Climb and self.state != State.WallSlide) self.state = State.Walk;
        } else if (rl.isKeyDown(rl.KeyboardKey.left) and allowLeftMovement) {
            self.velocity.x = -MOVE_SPEED;
            self.isFlipped = true;
            if (self.state != State.Jump and self.state != State.Climb and self.state != State.WallSlide) self.state = State.Walk;
        } else {
            if (self.state == State.Jump) {
                self.velocity.x *= AIR_RESISTANCE;
            } else {
                self.velocity.x = 0;
                if (self.state != State.WallSlide) self.state = State.Idle;
            }
        }

        if (rl.isKeyDown(rl.KeyboardKey.down) and self.state != State.Jump and self.state != State.WallSlide) {
            self.state = State.Duck;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.space) and self.state != State.Jump and self.state != State.WallSlide) {
            self.velocity.y = JUMP_FORCE;
            self.state = State.Jump;
        }

        if (self.state == State.WallSlide) {
            if (self.velocity.y > WALL_SLIDE_SPEED) {
                self.velocity.y = WALL_SLIDE_SPEED;
            }
        }

        self.velocity.y += GRAVITY * dt;

        updatePosition(self, dt, platforms);

        if (self.state == State.Walk or self.state == State.WallSlide) {
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

    fn updateWallSlideState(self: *Player, platforms: []const Platform) void {
        self.isTouchingWall = false;
        if (self.state == State.Jump) {
            if (!self.reachedApex and self.lastWallJumpDirection != 0) {
                return;
            }
            for (platforms) |platform| {
                // Detect left wall collision
                if (self.position.x <= platform.position.x + platform.size.x and
                    self.position.x > platform.position.x + platform.size.x - WALL_DETECTION_RANGE and
                    self.position.y + self.size.y > platform.position.y and
                    self.position.y < platform.position.y + platform.size.y)
                {
                    if (self.lastWallJumpDirection == -1 and
                        !self.reachedApex)
                    {
                        continue;
                    }
                    self.isTouchingWall = true;
                    self.wallDirection = -1;
                    self.state = State.WallSlide;
                    break;
                }
                // Detect right wall collision
                if (self.position.x + self.size.x >= platform.position.x and
                    self.position.x + self.size.x < platform.position.x + WALL_DETECTION_RANGE and
                    self.position.y + self.size.y > platform.position.y and
                    self.position.y < platform.position.y + platform.size.y)
                {
                    if (self.lastWallJumpDirection == 1 and
                        !self.reachedApex)
                    {
                        continue;
                    }
                    self.isTouchingWall = true;
                    self.wallDirection = 1;
                    self.state = State.WallSlide;
                    break;
                }
            }
        }
        // If not touching the wall, ensure the state is updated
        if (!self.isTouchingWall and self.state == State.WallSlide) {
            self.state = State.Jump;
        }
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
            State.WallSlide => {
                sourceRect = self.frames.jump;
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
