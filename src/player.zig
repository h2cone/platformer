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
    WallSlide,
};

pub const Player = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: rl.Vector2,
    isJumping: bool,
    state: PlayerState,

    // Wall sliding related properties
    isWallSliding: bool,
    // Wall direction, -1.0 for left wall, 1.0 for right wall
    wallDirection: f32,
    // Wall slide timer
    wallSlideTimer: f32,

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
    const JUMP_FORCE = -500.0;
    const GRAVITY = 800.0;
    const FRAME_SPEED = 30;

    // Gravity when wall sliding (less than normal gravity)
    const WALL_SLIDE_GRAVITY = 200.0;
    // Maximum wall slide time (in seconds)
    const WALL_SLIDE_MAX_TIME = 1.2;
    // Horizontal force for wall jump
    const WALL_JUMP_HORIZONTAL_FORCE = 300.0;
    // Vertical force for wall jump
    const WALL_JUMP_VERTICAL_FORCE = -450.0;

    // Character frame size in the tilesheet
    const FRAME_WIDTH = 96;
    const FRAME_HEIGHT = 96;

    pub fn init(initial_position: rl.Vector2) !Player {
        // Load the tilesheet
        const texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformerPack_character.png");

        return Player{
            .position = initial_position,
            .velocity = .{ .x = 0, .y = 0 },
            // Display size
            .size = .{ .x = 48, .y = 48 },
            .isJumping = false,
            .state = PlayerState.Idle,
            .texture = texture,
            // Initialize wall sliding related properties
            .isWallSliding = false,
            .wallDirection = 0.0,
            .wallSlideTimer = 0.0,
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
        // If wall sliding, update timer
        if (self.isWallSliding) {
            self.wallSlideTimer += dt;
            if (self.wallSlideTimer >= WALL_SLIDE_MAX_TIME) {
                // Time's up, stop wall sliding
                self.isWallSliding = false;
            }
        } else {
            self.wallSlideTimer = 0.0;
        }

        // Detect wall jump input
        if (self.isWallSliding and rl.isKeyPressed(rl.KeyboardKey.space)) {
            // Execute wall jump
            self.velocity.y = WALL_JUMP_VERTICAL_FORCE;
            // Jump from opposite direction
            self.velocity.x = -self.wallDirection * WALL_JUMP_HORIZONTAL_FORCE;
            // Reset state
            self.isWallSliding = false;
            self.isJumping = true;
            self.state = PlayerState.Jump;
            // Flip character based on jump direction
            self.isFlipped = self.velocity.x < 0;
        }

        // Determine horizontal movement and update state
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            self.velocity.x = MOVE_SPEED;
            self.isFlipped = false;
            if (!self.isJumping and !self.isWallSliding) self.state = PlayerState.Walk;
        } else if (rl.isKeyDown(rl.KeyboardKey.left)) {
            self.velocity.x = -MOVE_SPEED;
            self.isFlipped = true;
            if (!self.isJumping and !self.isWallSliding) self.state = PlayerState.Walk;
        } else {
            // Reset horizontal velocity if not wall sliding
            if (!self.isWallSliding) {
                self.velocity.x = 0;
            }
            if (!self.isJumping and !self.isWallSliding) self.state = PlayerState.Idle;
        }

        // Duck state if down key is pressed and not jumping
        if (rl.isKeyDown(rl.KeyboardKey.down) and !self.isJumping) {
            self.state = PlayerState.Duck;
        }

        // Jump
        if (rl.isKeyPressed(rl.KeyboardKey.space) and !self.isJumping and !self.isWallSliding) {
            self.velocity.y = JUMP_FORCE;
            self.isJumping = true;
            self.state = PlayerState.Jump;
        }

        // Apply gravity - different gravity when wall sliding
        if (self.isWallSliding) {
            self.velocity.y += WALL_SLIDE_GRAVITY * dt;
        } else {
            self.velocity.y += GRAVITY * dt;
        }

        // Mark as not wall sliding before updating position
        // Will be reset if wall collision is detected below
        self.isWallSliding = false;

        // Save the current position for more precise collision detection
        const oldPosition = self.position;

        // Update horizontal position first
        self.position.x += self.velocity.x * dt;

        // Detect horizontal collisions
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                // Use oldPosition to determine collision direction
                if (oldPosition.x + self.size.x <= platform.position.x) {
                    // Collision from the left - right wall
                    self.position.x = platform.position.x - self.size.x;

                    // Check if should enter wall slide state
                    if (self.isJumping and self.velocity.y > 0) {
                        self.isWallSliding = true;
                        self.wallDirection = 1.0; // right wall
                        self.state = PlayerState.WallSlide;
                    }
                } else if (oldPosition.x >= platform.position.x + platform.size.x) {
                    // Collision from the right - left wall
                    self.position.x = platform.position.x + platform.size.x;

                    // Check if should enter wall slide state
                    if (self.isJumping and self.velocity.y > 0) {
                        self.isWallSliding = true;
                        self.wallDirection = -1.0; // left wall
                        self.state = PlayerState.WallSlide;
                    }
                }

                // Reset horizontal velocity if not wall sliding
                if (!self.isWallSliding) {
                    self.velocity.x = 0;
                }
            }
        }

        // Update vertical position
        self.position.y += self.velocity.y * dt;

        // Detect vertical collisions
        for (platforms) |platform| {
            if (self.checkCollision(platform)) {
                // Use oldPosition to determine collision direction
                if (oldPosition.y + self.size.y <= platform.position.y) {
                    // Collision from above
                    self.position.y = platform.position.y - self.size.y;
                    self.velocity.y = 0;
                    self.isJumping = false;
                    self.isWallSliding = false; // End wall sliding when landing
                    // Reset state
                    if (self.velocity.x == 0) {
                        self.state = PlayerState.Idle;
                    } else {
                        self.state = PlayerState.Walk;
                    }
                } else if (oldPosition.y >= platform.position.y + platform.size.y) {
                    // Collision from below
                    self.position.y = platform.position.y + platform.size.y;
                    self.velocity.y = 0;
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
            PlayerState.WallSlide => {
                // Use climbing animation for wall slide state
                sourceRect = self.frames.climb1;
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
