#!/bin/bash

# Document Organizer Build Script
# Optimized for Apple Silicon macOS

set -e

echo "🚀 Building Document Organizer for macOS (Apple Silicon)..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This build script is designed for macOS only"
    exit 1
fi

# Check for Xcode command line tools
if ! command -v swift &> /dev/null; then
    echo "❌ Swift compiler not found. Please install Xcode command line tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

echo "📦 Building optimized release version..."

# Build with optimization for Apple Silicon
swift build \
    --configuration release \
    --arch arm64 \
    --build-path "$BUILD_DIR" \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization

# Copy the executable to a convenient location
cp "$BUILD_DIR/arm64-apple-macosx/release/DocumentOrganizerApp" "$BUILD_DIR/DocumentOrganizerApp"

echo "✅ Build completed successfully!"
echo "📁 Executable location: $BUILD_DIR/DocumentOrganizerApp"
echo ""
echo "To run the application:"
echo "   ./$BUILD_DIR/DocumentOrganizerApp"
echo ""
echo "To install system-wide (optional):"
echo "   sudo cp $BUILD_DIR/DocumentOrganizerApp /usr/local/bin/"
