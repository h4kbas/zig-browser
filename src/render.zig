// src/render.zig
const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const font = @import("font.zig");
const dom = @import("dom.zig");

pub fn chooseFont(family: font.FontFamily, inline_text: dom.Inline) font.Font {
    if (inline_text.bold and inline_text.italic) return family.bold_italic;
    if (inline_text.bold) return family.bold;
    if (inline_text.italic) return family.italic;
    return family.regular;
}

pub fn renderDiv(div: dom.Div) void {
    const x0 = div.x;
    const y0 = div.y;
    const x1 = x0 + div.style.width;
    const y1 = y0 - div.style.height;

    const color = div.style.background_color;

    const vertices = [_]f32{
        x0, y0, color[0], color[1], color[2],
        x1, y0, color[0], color[1], color[2],
        x1, y1, color[0], color[1], color[2],
        x0, y1, color[0], color[1], color[2],
    };

    const indices = [_]u32{ 0, 1, 2, 2, 3, 0 };

    c.glDisable(c.GL_TEXTURE_2D);
    c.glDisable(c.GL_BLEND);
    c.glEnableClientState(c.GL_VERTEX_ARRAY);
    c.glEnableClientState(c.GL_COLOR_ARRAY);
    c.glVertexPointer(2, c.GL_FLOAT, 5 * @sizeOf(f32), &vertices[0]);
    c.glColorPointer(3, c.GL_FLOAT, 5 * @sizeOf(f32), @ptrFromInt(@intFromPtr(&vertices[0]) + 2 * @sizeOf(f32)));
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, &indices[0]);
    c.glDisableClientState(c.GL_COLOR_ARRAY);
    c.glDisableClientState(c.GL_VERTEX_ARRAY);
}

pub fn renderInlines(family: font.FontFamily, x_start: f32, y_start: f32, inlines: []dom.Inline) void {
    var x = x_start;
    const y = y_start;

    // Enable blending with proper blend function for alpha textures
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glEnable(c.GL_TEXTURE_2D);

    for (inlines) |*text_inline| {
        const selected_font = chooseFont(family, text_inline.*);
        const scale = text_inline.font_size / 4000.0;
        const color = text_inline.color;

        c.glBindTexture(c.GL_TEXTURE_2D, selected_font.texture);

        // Set text color with full alpha - the texture's alpha will control visibility
        c.glColor4f(color[0], color[1], color[2], 1.0);

        // Debug print for text rendering
        std.debug.print("Rendering text: '{s}' with color: ({d:.3}, {d:.3}, {d:.3})\n", .{ text_inline.text, color[0], color[1], color[2] });

        for (text_inline.text) |ch| {
            if (ch < 32 or ch >= 128) continue;
            const cd = selected_font.chardata[ch - 32];

            const x0 = x + cd.xoff * scale;
            const y0 = y - cd.yoff * scale;
            const x1 = x0 + @as(f32, @floatFromInt(cd.x1 - cd.x0)) * scale;
            const y1 = y0 - @as(f32, @floatFromInt(cd.y1 - cd.y0)) * scale;

            // Record position for link clicking
            if (text_inline.is_link) {
                text_inline.pos_x = x0;
                text_inline.pos_y = y0;
                text_inline.width = x1 - x0;
                text_inline.height = y0 - y1;
            }

            // Convert bitmap coordinates to texture coordinates
            const tex_u0 = @as(f32, @floatFromInt(cd.x0)) / 512.0;
            const tex_u1 = @as(f32, @floatFromInt(cd.x1)) / 512.0;
            const tex_v0 = @as(f32, @floatFromInt(cd.y0)) / 512.0;
            const tex_v1 = @as(f32, @floatFromInt(cd.y1)) / 512.0;

            // Debug print for texture coordinates and character metrics
            std.debug.print("Char '{c}' pos: ({d:.3},{d:.3}) -> ({d:.3},{d:.3}), tex: ({d:.3},{d:.3}) -> ({d:.3},{d:.3})\n", .{ ch, x0, y0, x1, y1, tex_u0, tex_v0, tex_u1, tex_v1 });

            const vertices = [_]f32{
                x0, y0, tex_u0, tex_v0,
                x1, y0, tex_u1, tex_v0,
                x1, y1, tex_u1, tex_v1,
                x0, y1, tex_u0, tex_v1,
            };

            const indices = [_]u32{ 0, 1, 2, 2, 3, 0 };

            c.glEnableClientState(c.GL_VERTEX_ARRAY);
            c.glEnableClientState(c.GL_TEXTURE_COORD_ARRAY);
            c.glVertexPointer(2, c.GL_FLOAT, 4 * @sizeOf(f32), &vertices[0]);
            c.glTexCoordPointer(2, c.GL_FLOAT, 4 * @sizeOf(f32), @ptrFromInt(@intFromPtr(&vertices[0]) + 2 * @sizeOf(f32)));
            c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, &indices[0]);
            c.glDisableClientState(c.GL_TEXTURE_COORD_ARRAY);
            c.glDisableClientState(c.GL_VERTEX_ARRAY);

            x += cd.xadvance * scale;
        }
        x += 0.02; // Space between inlines
    }

    // Reset states
    c.glDisable(c.GL_TEXTURE_2D);
    c.glDisable(c.GL_BLEND);
    c.glColor4f(1.0, 1.0, 1.0, 1.0);
}

pub fn renderImage(texture_id: u32, x: f32, y: f32, width: f32, height: f32) void {
    c.glEnable(c.GL_TEXTURE_2D);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

    c.glBindTexture(c.GL_TEXTURE_2D, texture_id);
    c.glColor4f(1.0, 1.0, 1.0, 1.0);

    const vertices = [_]f32{
        x,         y,          0.0, 0.0,
        x + width, y,          1.0, 0.0,
        x + width, y - height, 1.0, 1.0,
        x,         y - height, 0.0, 1.0,
    };

    const indices = [_]u32{ 0, 1, 2, 2, 3, 0 };

    c.glEnableClientState(c.GL_VERTEX_ARRAY);
    c.glEnableClientState(c.GL_TEXTURE_COORD_ARRAY);
    c.glVertexPointer(2, c.GL_FLOAT, 4 * @sizeOf(f32), &vertices[0]);
    c.glTexCoordPointer(2, c.GL_FLOAT, 4 * @sizeOf(f32), @ptrFromInt(@intFromPtr(&vertices[0]) + 2 * @sizeOf(f32)));
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, &indices[0]);
    c.glDisableClientState(c.GL_TEXTURE_COORD_ARRAY);
    c.glDisableClientState(c.GL_VERTEX_ARRAY);
    c.glDisable(c.GL_TEXTURE_2D);
    c.glDisable(c.GL_BLEND);
}
