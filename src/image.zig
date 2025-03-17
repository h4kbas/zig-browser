const std = @import("std");
const c = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", "1");
    @cInclude("stb_image.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn loadImageAsTexture(allocator: std.mem.Allocator, url: []const u8) !u32 {
    const http = @import("http.zig");
    const data = try http.fetchHtml(allocator, url);

    var x: c_int = 0;
    var y: c_int = 0;
    var comp: c_int = 0;

    const img_data = c.stbi_load_from_memory(data.ptr, @as(c_int, @intCast(data.len)), &x, &y, &comp, 4);
    if (img_data == null) return error.ImageDecodeFailed;
    defer c.stbi_image_free(img_data);

    var texture_id: u32 = undefined;
    c.glGenTextures(1, &texture_id);
    c.glBindTexture(c.GL_TEXTURE_2D, texture_id);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, x, y, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, img_data);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    return texture_id;
}
