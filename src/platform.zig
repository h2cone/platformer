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
    const TILE_RECT = rl.Rectangle{ .x = 0, .y = 0, .width = TILE_SIZE, .height = TILE_SIZE };

    pub fn init() !void {
        Platform.texture = try rl.loadTexture("./assets/kenney_simplified-platformer-pack/Tilesheet/platformPack_tilesheet.png");
    }

    pub fn deinit() void {
        rl.unloadTexture(Platform.texture);
    }

    pub fn draw(self: Platform) void {
        rl.drawTextureRec(Platform.texture, TILE_RECT, self.position, rl.Color.white);
    }
};

// Define error set for platform operations
const PlatformError = error{
    FailedToLoadMap,
};

/// Creates an array of Platform objects from a Tiled map file
///
/// This function reads a Tiled JSON map file and converts its tile data into Platform objects.
/// Each non-zero tile ID in the first tile layer will be converted into a Platform.
///
/// Arguments:
///     map_path: Path to the Tiled map file (.tmj)
///     alloc: Memory allocator for creating the Platform array
///
/// Returns:
///     A slice of Platform objects. Caller owns the memory.
///
/// Errors:
///     error.FailedToLoadMap if the map file cannot be loaded
///     error.OutOfMemory if memory allocation fails
pub fn buildPlatforms(map_path: []const u8, alloc: std.mem.Allocator) ![]Platform {
    // Load the map file using cute_tiled
    const map = cute_tiled.cute_tiled_load_map_from_file(map_path.ptr, null);
    if (map == null) {
        return error.FailedToLoadMap;
    }
    // panic: member access within null pointer of type 'cute_tiled_map_internal_t'
    // defer cute_tiled.cute_tiled_free_map(map);

    // Count how many platforms we need to create
    var count: usize = 0;
    var layer = map.*.layers;

    while (layer != null) {
        // We're only processing the first layer
        if (layer.*.type.ptr != null and std.mem.eql(u8, std.mem.span(layer.*.type.ptr), "tilelayer")) {
            const data: [*c]c_int = layer.*.data;
            const width = @as(usize, @intCast(layer.*.width));
            const height = @as(usize, @intCast(layer.*.height));

            // Count non-zero tiles
            for (0..width * height) |i| {
                if (data[i] > 0) {
                    count += 1;
                }
            }

            // We only need the first tile layer
            break;
        }
        layer = layer.*.next;
    }

    // Allocate memory for platforms
    var platforms = try alloc.alloc(Platform, count);

    // Create platforms from map data
    var platformIndex: usize = 0;
    // Reset to first layer
    layer = map.*.layers;

    while (layer != null) {
        if (layer.*.type.ptr != null and std.mem.eql(u8, std.mem.span(layer.*.type.ptr), "tilelayer")) {
            const data: [*c]c_int = layer.*.data;
            const width = @as(usize, @intCast(layer.*.width));
            const height = @as(usize, @intCast(layer.*.height));

            for (0..height) |row| {
                for (0..width) |col| {
                    // Convert two-dimensional coordinates to a one-dimensional array index
                    const tileIndex = row * width + col;
                    if (data[tileIndex] > 0) {
                        // Create a platform for this tile
                        platforms[platformIndex] = Platform{
                            // Convert grid coordinates to pixel coordinates
                            .position = rl.Vector2{
                                .x = @as(f32, @floatFromInt(col)) * Platform.TILE_SIZE,
                                .y = @as(f32, @floatFromInt(row)) * Platform.TILE_SIZE,
                            },
                            .size = rl.Vector2{
                                .x = @floatFromInt(Platform.TILE_SIZE),
                                .y = @floatFromInt(Platform.TILE_SIZE),
                            },
                        };
                        platformIndex += 1;
                    }
                }
            }
            // We only need the first tile layer
            break;
        }
        layer = layer.*.next;
    }

    return platforms;
}
