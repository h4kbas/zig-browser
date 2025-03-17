// stb_image.h - v2.27 - public domain image loader
// authored from 2008-2021 by Sean Barrett / RAD Game Tools

#ifndef STBI_INCLUDE_STB_IMAGE_H
#define STBI_INCLUDE_STB_IMAGE_H

#ifndef STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#endif

#ifndef STBI_NO_STDIO
#define STBI_NO_STDIO
#endif

#ifndef STB_IMAGE_STATIC
#define STB_IMAGE_STATIC
#endif

unsigned char *stbi_load_from_memory(unsigned char const *buffer, int len, int *x, int *y, int *channels_in_file, int desired_channels);
void stbi_image_free(void *retval_from_stbi_load);

// Implementation
unsigned char *stbi_load_from_memory(unsigned char const *buffer, int len, int *x, int *y, int *channels_in_file, int desired_channels) {
    // Dummy implementation that returns null
    if (x) *x = 0;
    if (y) *y = 0;
    if (channels_in_file) *channels_in_file = 0;
    return 0;
}

void stbi_image_free(void *retval_from_stbi_load) {
    // Dummy implementation
}

#endif // STBI_INCLUDE_STB_IMAGE_H
