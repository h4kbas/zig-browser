#!/bin/bash

# Create fonts directory if it doesn't exist
mkdir -p lib

# Download Roboto fonts from a mirror that provides TTF files
curl -L "https://github.com/googlefonts/roboto/raw/main/src/hinted/Roboto-Regular.ttf" -o lib/Roboto-Regular.ttf
curl -L "https://github.com/googlefonts/roboto/raw/main/src/hinted/Roboto-Bold.ttf" -o lib/Roboto-Bold.ttf
curl -L "https://github.com/googlefonts/roboto/raw/main/src/hinted/Roboto-Italic.ttf" -o lib/Roboto-Italic.ttf
curl -L "https://github.com/googlefonts/roboto/raw/main/src/hinted/Roboto-BoldItalic.ttf" -o lib/Roboto-BoldItalic.ttf 