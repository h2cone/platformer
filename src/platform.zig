const rl = @import("raylib");
const cute_tiled = @cImport({
    @cInclude("cute_tiled.h");
});
const std = @import("std");

pub const Platform = struct {
    position: rl.Vector2,
    size: rl.Vector2,

    // Shared texture and frame definitions
    var texture: rl.Texture2D = undefined;
    // Size of each tile in the tilesheet
    const TILE_SIZE = 64;
    const TILE = rl.Rectangle{ .x = 0, .y = 0, .width = TILE_SIZE, .height = TILE_SIZE };

    pub fn init() !void {
        Platform.texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformPack_tilesheet.png");
    }

    pub fn deinit() void {
        rl.unloadTexture(Platform.texture);
    }

    pub fn draw(self: Platform) void {
        // Calculate how many tiles we need to draw based on platform width
        const tiles_count = @as(usize, @intFromFloat(@ceil(self.size.x / @as(f32, TILE_SIZE))));

        // Draw each tile of the platform
        var i: usize = 0;
        while (i < tiles_count) : (i += 1) {
            const pos = rl.Vector2{
                .x = self.position.x + @as(f32, @floatFromInt(i)) * TILE_SIZE,
                .y = self.position.y,
            };
            rl.drawTextureRec(Platform.texture, TILE, pos, rl.Color.white);
        }
    }
};

// Function to load platforms from Tiled map file
pub fn loadPlatformsFromTiled(allocator: std.mem.Allocator, map_path: []const u8) ![]Platform {
    // Load the Tiled map
    const map = cute_tiled.cute_tiled_load_map_from_file(map_path.ptr, null);
    if (map == null) {
        return error.FailedToLoadMap;
    }
    // defer cute_tiled.cute_tiled_free_map(map)

    // Get map dimensions and tileset info
    const map_tilewidth = map.*.tilewidth;
    const tileset = map.*.tilesets;
    if (tileset == null) {
        return error.NoTilesetFound;
    }

    // Calculate scale factor between map tiles and tileset tiles
    const scale = @as(f32, @floatFromInt(tileset.*.tilewidth)) / @as(f32, @floatFromInt(map_tilewidth));

    // Track continuous platform segments
    var platforms = std.ArrayList(Platform).init(allocator);
    errdefer platforms.deinit();

    // Process each layer
    var layer = map.*.layers;
    while (layer != null) : (layer = layer.*.next) {
        if (layer.*.data == null) continue;

        const width = layer.*.width;
        const height = layer.*.height;
        const data = layer.*.data;

        // For each row (starting from bottom, since Tiled uses bottom-left origin)
        var y: i32 = @intCast(height - 1);
        while (y >= 0) : (y -= 1) {
            var platform_start: ?usize = null;
            var platform_width: usize = 0;

            // Process each column
            var x: usize = 0;
            while (x < width) : (x += 1) {
                const index = @as(usize, @intCast(y)) * @as(usize, @intCast(width)) + x;
                const tile_id = data[index];

                // If we found a valid tile (platform)
                if (tile_id > 0) {
                    // If we're not tracking a platform yet, start one
                    if (platform_start == null) {
                        platform_start = x;
                        platform_width = 1;
                    } else {
                        // Extend the current platform
                        platform_width += 1;
                    }
                } else if (platform_start != null) {
                    // End of a platform segment, create a platform
                    try createPlatformSegment(&platforms, platform_start.?, platform_width, y, map_tilewidth, scale);
                    platform_start = null;
                    platform_width = 0;
                }
            }

            // Check if we have a platform at the end of the row
            if (platform_start != null) {
                try createPlatformSegment(&platforms, platform_start.?, platform_width, y, map_tilewidth, scale);
            }
        }
    }

    // Create an array to return
    var result = try allocator.alloc(Platform, platforms.items.len);
    errdefer allocator.free(result);

    for (platforms.items, 0..) |platform, i| {
        result[i] = platform;
    }

    // Clean up resources
    platforms.deinit();

    return result;
}

// Helper function to create a platform segment
fn createPlatformSegment(platforms: *std.ArrayList(Platform), start_x: usize, width: usize, y: i32, map_tilewidth: c_int, scale: f32) !void {
    // Convert start_x to the same type as map_tilewidth before multiplication
    const start_x_int: c_int = @intCast(start_x);
    const width_int: c_int = @intCast(width);

    // Calculate position and size in map tile coordinates
    // Since each tile in the pattern "1, 0" represents one platform tile,
    // we need to halve the effective width to account for the gaps
    const position_x = @as(f32, @floatFromInt(start_x_int * map_tilewidth));
    const position_y = @as(f32, @floatFromInt(y * map_tilewidth));
    const size_x = @as(f32, @floatFromInt(width_int * map_tilewidth)) / 2.0;

    // Scale up to match tileset dimensions
    const platform = Platform{
        .position = .{
            .x = position_x * scale / 2.0, // Divide by 2 to account for the "1, 0" pattern
            .y = position_y * scale,
        },
        .size = .{
            .x = size_x * scale,
            .y = @as(f32, @floatFromInt(Platform.TILE_SIZE)),
        },
    };

    try platforms.append(platform);
}
