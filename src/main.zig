const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const font = @import("font.zig");
const dom = @import("dom.zig");
const render = @import("render.zig");
const http = @import("http.zig");
const image = @import("image.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Initialize GLFW and OpenGL
    if (c.glfwInit() == 0) return;
    defer c.glfwTerminate();

    const window = c.glfwCreateWindow(800, 600, "Zig Browser", null, null);
    if (window == null) return;
    c.glfwMakeContextCurrent(window);

    // Enable blending for text rendering
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

    // Load fonts
    const fonts = try font.FontFamily.init(allocator);

    // Initialize history
    var history = dom.History.init(allocator);

    // Load initial page
    const start_url = "https://example.com";
    const body = try http.fetchHtml(allocator, start_url);
    try history.visit(allocator, start_url, body);

    // Mouse and keyboard handling
    var mouseClicked = false;
    var mouse_x: f64 = 0;
    var mouse_y: f64 = 0;

    const CallbackData = struct {
        clicked: *bool,
        x: *f64,
        y: *f64,
        history: *dom.History,
    };

    var mouse_data = CallbackData{
        .clicked = &mouseClicked,
        .x = &mouse_x,
        .y = &mouse_y,
        .history = &history,
    };

    const CallbackHandler = struct {
        data: *CallbackData,

        pub fn mouseCallback(win: ?*c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
            const user_ptr = c.glfwGetWindowUserPointer(win.?);
            const ctx = @as(*@This(), @ptrCast(@alignCast(user_ptr)));
            if (button == c.GLFW_MOUSE_BUTTON_LEFT and action == c.GLFW_PRESS) {
                ctx.data.clicked.* = true;
                var x: f64 = undefined;
                var y: f64 = undefined;
                c.glfwGetCursorPos(win.?, &x, &y);
                ctx.data.x.* = x;
                ctx.data.y.* = y;
            }
        }

        pub fn keyCallback(win: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
            const user_ptr = c.glfwGetWindowUserPointer(win.?);
            const ctx = @as(*@This(), @ptrCast(@alignCast(user_ptr)));
            if (action == c.GLFW_PRESS) {
                if (key == c.GLFW_KEY_LEFT or key == c.GLFW_KEY_B) _ = ctx.data.history.back();
                if (key == c.GLFW_KEY_RIGHT or key == c.GLFW_KEY_F) _ = ctx.data.history.forward();
            }
        }
    };

    var callback_handler = CallbackHandler{ .data = &mouse_data };
    c.glfwSetWindowUserPointer(window, &callback_handler);
    _ = c.glfwSetMouseButtonCallback(window, CallbackHandler.mouseCallback);
    _ = c.glfwSetKeyCallback(window, CallbackHandler.keyCallback);

    // Main render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        c.glClearColor(1.0, 1.0, 1.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        if (history.currentPage()) |page| {
            // Render divs with text
            for (page.divs) |div| {
                render.renderDiv(div);
                render.renderInlines(fonts, div.x + div.style.padding, div.y - div.style.padding, div.inlines);
            }

            // Render images
            for (page.images) |img| {
                const tex_id = image.loadImageAsTexture(allocator, img.url) catch continue;
                render.renderImage(tex_id, img.x, img.y, img.width, img.height);
            }

            // Handle link clicks
            if (mouseClicked) {
                const win_width: f32 = 800.0;
                const win_height: f32 = 600.0;
                const norm_x = @as(f32, @floatCast(mouse_x)) / win_width;
                const norm_y = @as(f32, @floatCast(mouse_y)) / win_height;
                const ogl_x: f32 = norm_x * 2.0 - 1.0;
                const ogl_y: f32 = -(norm_y * 2.0 - 1.0);

                // Check if clicked on any link in div inlines
                for (page.divs) |div| {
                    if (dom.onMouseClick(ogl_x, ogl_y, div.inlines)) |url| {
                        std.debug.print("Navigating to: {s}\n", .{url});
                        const new_body = http.fetchHtml(allocator, url) catch continue;
                        history.visit(allocator, url, new_body) catch continue;
                        break;
                    }
                }

                mouseClicked = false;
            }
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
