const std = @import("std");

pub fn fetchHtml(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    _ = url;
    const dummy_html = "<html><body><h1>Hello, World!</h1></body></html>";
    return try allocator.dupe(u8, dummy_html);
}
