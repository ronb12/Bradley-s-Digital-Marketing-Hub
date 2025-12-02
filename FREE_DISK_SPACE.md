# 🚨 CRITICAL: Disk Full - App Crashing

Your disk is **100% full** (only 53MB free). This is causing the app to crash because it cannot write temporary files or logs.

## Immediate Actions to Free Space:

### 1. Clear Xcode DerivedData (Safe - Can be regenerated)
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 2. Clear Old Simulator Devices (Safe if you don't need old data)
Delete unused simulators:
- Go to Xcode → Window → Devices and Simulators
- Delete old/unused simulators
- Or run: `xcrun simctl delete unavailable`

### 3. Clear Simulator Logs and Data
```bash
# Clear logs from current simulator
xcrun simctl spawn "64136F6E-9C64-46E7-9C88-9426C496CD60" log erase --all

# Or delete the simulator's data container (keeps the simulator)
# WARNING: This deletes app data
```

### 4. Clear System Caches (Safe)
```bash
# Clear Xcode caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Clear system caches
sudo rm -rf /Library/Caches/*
```

### 5. Clear Large Files
- Empty Trash
- Clear Downloads folder
- Check for large duplicate files
- Use Disk Utility to see what's taking space

### 6. After Freeing Space:
1. Restart your Mac
2. Rebuild the app: `⌘⇧K` then `⌘R` in Xcode
3. Launch the app again

## Current Space Usage:
- **CoreSimulator**: 13GB
- **DerivedData**: 213MB
- **Total Free**: Only 53MB (CRITICAL!)

## Recommended Minimum:
- Free up at least **2-3GB** for Xcode and simulator to work properly
- **5-10GB** is ideal

