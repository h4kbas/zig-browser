{
    .name = "zig-browser",
    .version = "0.1.0",
    .dependencies = {
        // Example: If you want to include zfetch as a dependency, uncomment and adjust
        // .zfetch = "https://github.com/MasterQ32/zfetch/archive/refs/heads/master.tar.gz",
    },
    .description = "A Zig browser built from scratch using OpenGL and custom layout engine.",
    .license = "MIT",
    .links = [
        "GL",        // OpenGL
        "glfw",      // GLFW windowing
    ],
    .paths = [
        "src",
        "lib",      // Where stb_truetype.h, stb_image.h, fonts are located
    ],
}
