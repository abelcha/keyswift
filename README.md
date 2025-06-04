# KeyShift

A native Swift application for quickly switching between application windows on macOS.

## Features

- **F1**: Toggle between browser windows (remembers last used browser)
- **F2**: Toggle between code editor windows (remembers last used editor)
- **F3**: Toggle between terminal windows (remembers last used terminal)
- **Cmd+F1**: Cycle through all browser windows
- **Cmd+F2**: Cycle through all code editor windows
- **Cmd+F3**: Cycle through all terminal windows

## How It Works

- When you press a function key (F1, F2, F3), KeyShift remembers the last window you used within that category.
- For example, if you press F1 to switch to Chrome, then F1 to Safari, then F2 to VS Code, then F1 again - it will take you back to Safari (not Chrome) because Safari was the last browser you used.
- This makes it much faster to switch between the windows you most commonly use.

## Installation

1. Build the application:
   ```
   cd /me/config/hammerspoon/KeyShift
   swift build -c release
   ```

2. Run the application:
   ```
   ./.build/release/KeyShift
   ```

3. For development/debugging:
   ```
   swift build
   ./.build/debug/KeyShift
   ```

## Requirements

- macOS 10.15 or later
- Accessibility permissions must be granted to allow window switching

## Troubleshooting

If hotkeys are not working:
1. Make sure KeyShift has accessibility permissions
2. Check that F1-F3 keys aren't being captured by system features
3. Use the "Check Hotkey Status" option from the menu bar icon
4. Try the "Reinstall Hotkeys" option from the menu bar icon

## Supported Applications

### Browsers
Safari, Chrome, Firefox, Brave, Chromium, Edge, Kagi, Thorium, etc.

### Code Editors
VSCode, VSCodium, Zed, Lapce, etc.

### Terminals
iTerm2, Terminal.app, Hyper, WezTerm, Alacritty, Kitty, etc.
