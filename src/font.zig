const std = @import("std");
const c = @cImport({
    @cInclude("stb_truetype.h");
    @cInclude("GLFW/glfw3.h");
});

pub const Font = struct {
    texture: u32,
    chardata: [96]c.stbtt_bakedchar,
};

pub const FontFamily = struct {
    regular: Font,
    bold: Font,
    italic: Font,
    bold_italic: Font,

    pub fn init(allocator: std.mem.Allocator) !FontFamily {
        return FontFamily{
            .regular = try loadFont(allocator, "lib/Roboto-Regular.ttf"),
            .bold = try loadFont(allocator, "lib/Roboto-Bold.ttf"),
            .italic = try loadFont(allocator, "lib/Roboto-Italic.ttf"),
            .bold_italic = try loadFont(allocator, "lib/Roboto-BoldItalic.ttf"),
        };
    }
};

pub fn loadFont(allocator: std.mem.Allocator, path: []const u8) !Font {
    std.debug.print("Loading font from path: {s}\n", .{path});

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const size = try file.getEndPos();
    std.debug.print("Font file size: {d} bytes\n", .{size});

    const buffer = try allocator.alloc(u8, size);
    defer allocator.free(buffer);
    const bytes_read = try file.readAll(buffer);
    std.debug.print("Read {d} bytes from font file\n", .{bytes_read});

    // Verify TTF magic number
    if (bytes_read < 4 or !std.mem.eql(u8, buffer[0..4], &[_]u8{ 0x00, 0x01, 0x00, 0x00 })) {
        std.debug.print("Warning: Font file does not have TTF magic number\n", .{});
        std.debug.print("First 16 bytes: ", .{});
        for (buffer[0..16]) |b| {
            std.debug.print("{x:0>2} ", .{b});
        }
        std.debug.print("\n", .{});
    }

    const width = 512;
    const height = 512;
    const bitmap = try allocator.alloc(u8, width * height);
    defer allocator.free(bitmap);
    @memset(bitmap, 0);

    var chardata: [96]c.stbtt_bakedchar = undefined;
    const result = c.stbtt_BakeFontBitmap(buffer.ptr, 0, 64.0, bitmap.ptr, width, height, 32, 96, &chardata);
    std.debug.print("Font baking result: {d}\n", .{result});
    if (result <= 0) {
        return error.FontBakeFailed;
    }

    // Debug: Check bitmap content
    var non_zero_pixels: usize = 0;
    var max_value: u8 = 0;
    var min_non_zero: u8 = 255;
    for (bitmap[0 .. width * height]) |pixel| {
        if (pixel > 0) {
            non_zero_pixels += 1;
            if (pixel > max_value) max_value = pixel;
            if (pixel < min_non_zero) min_non_zero = pixel;
        }
    }
    std.debug.print("Bitmap stats: {d} non-zero pixels, min non-zero: {d}, max value: {d}\n", .{ non_zero_pixels, min_non_zero, max_value });

    // Debug: Print a small sample of the bitmap where we expect text to be
    std.debug.print("Bitmap sample (20x10 from y=100):\n", .{});
    for (0..10) |y| {
        for (0..20) |x| {
            const pixel = bitmap[(y + 100) * width + x];
            if (pixel > 0) {
                std.debug.print("XX ", .{});
            } else {
                std.debug.print(".. ", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    // Create texture
    var texture: c_uint = undefined;
    c.glGenTextures(1, &texture);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);

    // Set texture parameters for proper alpha texture rendering
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);

    // Upload texture with alpha format
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_ALPHA,
        @intCast(width),
        @intCast(height),
        0,
        c.GL_ALPHA,
        c.GL_UNSIGNED_BYTE,
        bitmap.ptr,
    );

    // Debug print bitmap info
    std.debug.print("Font texture created: {d}x{d}\n", .{ width, height });

    // Print first few pixels for debugging
    std.debug.print("First 10 pixels: ", .{});
    for (bitmap[0..@min(10, bitmap.len)]) |pixel| {
        std.debug.print("{d} ", .{pixel});
    }
    std.debug.print("\n", .{});

    return Font{ .texture = texture, .chardata = chardata };
}
