const std = @import("std");

pub fn parseHtml(allocator: std.mem.Allocator, html: []const u8) !Page {
    _ = html; // TODO: Actually parse HTML

    // Create a test div with some text
    var inlines = try allocator.alloc(Inline, 2);
    inlines[0] = Inline{
        .text = "Hello, ",
        .color = .{ 0.0, 0.0, 0.0 },
        .font_size = 16.0,
        .bold = false,
        .italic = false,
        .underline = false,
        .is_link = false,
        .href = null,
        .pos_x = -0.8,
        .pos_y = 0.5,
        .width = 0.2,
        .height = 0.1,
    };
    inlines[1] = Inline{
        .text = "World!",
        .color = .{ 0.0, 0.0, 1.0 },
        .font_size = 16.0,
        .bold = true,
        .italic = false,
        .underline = true,
        .is_link = true,
        .href = "https://example.com/world",
        .pos_x = -0.6,
        .pos_y = 0.5,
        .width = 0.2,
        .height = 0.1,
    };

    var divs = try allocator.alloc(Div, 1);
    divs[0] = Div{
        .x = -0.9,
        .y = 0.6,
        .style = Style{
            .padding = 0.05,
            .margin = 0.1,
            .width = 0.8,
            .height = 0.15,
            .background_color = .{ 0.9, 0.9, 0.9 },
        },
        .inlines = inlines,
    };

    return Page{
        .url = try allocator.dupe(u8, "https://example.com"),
        .divs = divs,
        .images = &[_]Image{},
    };
}

pub const Style = struct {
    padding: f32 = 0,
    margin: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
    background_color: [3]f32 = .{ 1.0, 1.0, 1.0 },
};

pub const Inline = struct {
    text: []const u8,
    color: [3]f32,
    font_size: f32,
    bold: bool,
    italic: bool,
    underline: bool,
    is_link: bool,
    href: ?[]const u8,
    pos_x: f32,
    pos_y: f32,
    width: f32,
    height: f32,
};

pub const Div = struct {
    x: f32,
    y: f32,
    style: Style,
    inlines: []Inline,
};

pub const Image = struct {
    x: f32,
    y: f32,
    url: []const u8,
    width: f32,
    height: f32,
    margin: f32,
};

pub const Page = struct {
    url: []const u8,
    divs: []Div,
    images: []Image,
};

pub const History = struct {
    pages: std.ArrayList(Page),
    current: usize,

    pub fn init(allocator: std.mem.Allocator) History {
        return History{
            .pages = std.ArrayList(Page).init(allocator),
            .current = 0,
        };
    }

    pub fn visit(self: *History, allocator: std.mem.Allocator, url: []const u8, body: []const u8) !void {
        const parsed = try parseHtml(allocator, body);
        const page = Page{
            .url = try allocator.dupe(u8, url),
            .divs = parsed.divs,
            .images = parsed.images,
        };
        if (self.pages.items.len > 0 and self.current < self.pages.items.len - 1) {
            try self.pages.resize(self.current + 1);
        }
        try self.pages.append(page);
        self.current = self.pages.items.len - 1;
    }

    pub fn back(self: *History) bool {
        if (self.current > 0) {
            self.current -= 1;
            return true;
        }
        return false;
    }

    pub fn forward(self: *History) bool {
        if (self.current + 1 < self.pages.items.len) {
            self.current += 1;
            return true;
        }
        return false;
    }

    pub fn currentPage(self: *History) ?Page {
        if (self.pages.items.len > 0) return self.pages.items[self.current];
        return null;
    }
};

pub fn onMouseClick(x: f32, y: f32, inlines: []Inline) ?[]const u8 {
    for (inlines) |text_inline| {
        if (text_inline.is_link and
            x >= text_inline.pos_x and x <= text_inline.pos_x + text_inline.width and
            y >= text_inline.pos_y and y <= text_inline.pos_y + text_inline.height)
        {
            return text_inline.href;
        }
    }
    return null;
}
