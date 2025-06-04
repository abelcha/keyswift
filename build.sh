#!/bin/bash

# Build in release mode for better performance
echo "Building KeyShift in release mode..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "KeyShift is ready to run with: ./.build/release/KeyShift"
    
    # Ask if user wants to run the app now
    read -p "Run KeyShift now? (y/n) " choice
    case "$choice" in 
      y|Y ) ./.build/release/KeyShift ;;
      * ) echo "You can run KeyShift later with: ./.build/release/KeyShift" ;;
    esac
else
    echo "Build failed!"
fi
