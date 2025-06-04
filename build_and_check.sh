#!/bin/bash

# Build in release mode for better performance
echo "Building KeyShift in release mode..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo ""
    echo "Launching KeyShift and checking hotkey registration..."
    echo "This will display for 5 seconds, then exit automatically."
    echo ""
    
    # Run with a timeout - this will show if hotkeys registered properly
    # and then exit automatically so we don't leave the app running
    (sleep 5 && killall KeyShift) &
    ./.build/release/KeyShift
    
    echo ""
    echo "Check completed. If all hotkeys showed as 'Registered', you're good to go!"
    echo "To use KeyShift permanently, run: ./.build/release/KeyShift"
else
    echo "Build failed!"
fi
