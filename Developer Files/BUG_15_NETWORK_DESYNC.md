# BUG 15: Network Desync When Idle (AIMeE Appears to Teleport into Ground on Dedicated Servers)

> **Note**: Originally labeled Bug 10 during investigation, but renumbered to Bug 15 to avoid confusion with the original Bug 10 (distance-based queue sorting). This is a network synchronization issue discovered during dedicated server testing in November 2026.

## Problem Description
On dedicated servers, after a seemingly random amount of time, when far away from AIMeEs:
1. AIMeEs appear to teleport into/below the ground
2. Rotation angles appear to snap to random values  
3. **Issue resolves completely after client re-login (without server restart or code changes)**

This behavior is characteristic of **network desynchronization** rather than actual server-side teleportation.

## Root Cause Analysis

### Network Culling Issue (The Real Problem)
The issue is a network desynchronization caused by culling on dedicated servers:

1. **Server Physics Running**: AIMeE gets stuck after ~60 seconds of minimal movement
2. **Unstuck() Triggered**: `TryUnstuck()` fires on the server and calls `Unstuck()`
3. **Client Out of Range**: When the player is far away, the client is in **culling range and stops receiving network updates** for that entity
4. **Position Changes Missed**: The AIMeE's position/rotation is modified (either by original teleport or physics escape), but the **client never receives this update**
5. **Stale Position**: Client's cached position diverges from server reality
6. **Re-login Fixes It**: When re-logging in, the client receives a full state synchronization that corrects the position

### Why This Only Happens on Dedicated Servers
- Dedicated servers use aggressive network culling to reduce bandwidth
- Single-player/co-op doesn't have this culling issue  
- On dedicated servers, clients far away genuinely don't receive updates for distant entities

## Solution Implemented

### Bug 9 Physics-Based Escape (Prerequisite)
- Prevents original teleporting behavior with `Random.Range(0,1)` int bug
- Replaces with small backward impulse + gentle steering to help escape stuck state

### Bug 15 Idle-Based Sync via LaunchPad Booster (CRITICAL FIX)
**Detects idle AIMeEs and forces position sync to bypass network culling:**

When AIMeE velocity drops below 0.05 (idle state):
1. Every 2 seconds, send position/rotation to ALL clients via `AIMeeSyncMessage`
2. Message is sent via LaunchPad Booster's `INetworkMessage` which bypasses vanilla culling
3. All clients receive the update regardless of distance
4. Ensures clients stay synchronized even when AIMeE is out of culling range

**Implementation:**
1. Created `AIMeeSyncMessage` implementing `INetworkMessage` interface
2. Registered during plugin initialization with LaunchPad Booster
3. `Bug15_IdleSyncFix.PhysicsUpdate_Postfix()` detects idle state and sends sync
4. `AIMeeSyncMessage.Process()` receives on clients and updates position/rotation directly

## Files Modified
- `Plugin.cs`: 
  - Added `AIMeeSyncMessage` class implementing `INetworkMessage`
  - Added `Bug15_IdleSyncFix` class that detects idle AIMeEs and triggers syncs
  - `Bug15_IdleSyncFix.PhysicsUpdate_Postfix()` sends LaunchPad Booster message when idle
  - Plugin.Awake() registers the message with LaunchPad Booster's `Mod.Networking` system
- `AimeeBugFixes.csproj`: Added LaunchPadBooster assembly reference with conditional path check

## Why This Fixes The Issue

**Before Fix:**
1. Server physics runs → AIMeE velocity drops below 0.05 (idle)
2. Client far away (culled) → vanilla networking stops sending updates
3. Client sees stale position → appears to teleport into ground when re-entering range

**After Fix:**
1. Server detects idle (velocity < 0.05) every 2 seconds
2. LaunchPad Booster message sent to ALL clients (no culling checks)
3. Client receives update immediately → shows correct position in real-time
4. No desynchronization, no apparent teleportation, smooth continuity when returning to range

## Testing Recommendations

**Critical Test** (reproduces the original bug):
1. Install both AimeeBugFixes mod AND LaunchPadBooster mod
2. Start dedicated server with both mods
3. Connect client and position AIMeE 
4. **Move far away** (out of culling range) from the AIMeE
5. Wait for AIMeE to become idle (no movement for several seconds)
6. **Before Fix**: AIMeE appears in wrong position when you look at it
7. **After Fix**: AIMeE is in correct position, smooth continuity when you return to range

**Other Tests:**
- Verify position stays synchronized even when AIMeE is idle
- Confirm smooth position updates every 2 seconds while idle
- Monitor logs for "Bug15-IdleSync" and "Bug15-SyncMsg" messages
- Test with multiple AIMeEs far apart to verify each one gets its sync
- Verify no excessive network traffic (should only sync idle AIMeEs every 2 seconds)

## Dependencies
- **LaunchPadBooster mod** must be installed on the server and clients
  - Provides the `INetworkMessage` infrastructure
  - Handles mod registration and networking
  - Available through Stationeers mod manager
- BepInEx 5.4.x (for plugin loading)

## Compatibility Notes
- Works on dedicated servers and single-player/co-op
- Respects existing patches
- No breaking changes to other mods
- Requires LaunchPadBooster as a dependency (mod will warn if missing)

## Performance Impact
- Negligible - only sends messages every 2 seconds for IDLE AIMeEs (at rest)
- When AIMeE is actively moving, no sync messages are sent (vanilla networking works fine)
- Network message is small (under 100 bytes: ReferenceId + position + rotation)
- All clients receive the message (broadcast), but processing is fast (simple position update)
- No impact on moving AIMeEs or during active gameplay
