const std = @import("std");
const cute_tiled = @cImport({
    @cInclude("cute_tiled.h");
});

pub fn main() !void {
    // load map
    const map = cute_tiled.cute_tiled_load_map_from_file("./assets/land.tmj", null);
    if (map == null) {
        std.debug.print("Failed to load map\n", .{});
        return;
    }
    // iterate layers
    var layer = map.*.layers;
    while (layer != null) {
        if (layer.*.name.ptr != null) {
            std.debug.print("layer.name: {s}\n", .{layer.*.name.ptr});
            std.debug.print("layer.width: {}\n", .{layer.*.width});
            std.debug.print("layer.height: {}\n", .{layer.*.height});
            const data: [*c]c_int = layer.*.data;

            std.debug.print("\nAll layer data:\n", .{});
            for (0..@intCast(layer.*.height)) |row| {
                std.debug.print("Row {d:2}: ", .{row});
                for (0..@intCast(layer.*.width)) |col| {
                    const index = @as(usize, @intCast(row)) * @as(usize, @intCast(layer.*.width)) + @as(usize, @intCast(col));
                    std.debug.print("{d:2} ", .{data[index]});
                }
                std.debug.print("\n", .{});
            }
        }
        layer = layer.*.next;
    }
    // iterate tilesets
    var tileset = map.*.tilesets;
    while (tileset != null) {
        if (tileset.*.name.ptr != null) {
            std.debug.print("tileset.name: {s}\n", .{tileset.*.name.ptr});
            std.debug.print("tileset.image: {s}\n", .{tileset.*.image.ptr});
            std.debug.print("tileset.tilewidth: {}\n", .{tileset.*.tilewidth});
            std.debug.print("tileset.tileheight: {}\n", .{tileset.*.tileheight});
        }
        tileset = tileset.*.next;
    }
}
