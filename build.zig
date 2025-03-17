const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-browser",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Link with system GLFW
    exe.linkSystemLibrary("glfw");

    // Add OpenGL framework for macOS
    exe.linkFramework("OpenGL");

    // Add stb headers
    exe.addIncludePath(.{ .cwd_relative = "lib" });

    // Compile and link stb_truetype implementation
    const stb_truetype = b.addObject(.{
        .name = "stb_truetype",
        .target = target,
        .optimize = optimize,
    });
    stb_truetype.addCSourceFile(.{
        .file = .{ .cwd_relative = "lib/stb_truetype_impl.c" },
        .flags = &[_][]const u8{},
    });
    stb_truetype.addIncludePath(.{ .cwd_relative = "lib" });
    exe.addObject(stb_truetype);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
