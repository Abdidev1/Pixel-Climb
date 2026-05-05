# Setup Guide

This page walks through placing scripts into your Roblox place and configuring them correctly before publishing.

---

## Prerequisites

- Roblox Studio installed and up to date
- Your place file open in Studio
- The game published to Roblox (DataStore calls do not work offline)

---

## 1. Server Scripts

Place each file from `src/server/` into **ServerScriptService** in the following order. The order matters because `PrestigeScript` and `ServerSkipStageHandler` both `require` `CheckpointAndLeaderboard`.

1. `CheckpointAndLeaderboard.luau`
2. `PrestigeScript.luau`
3. `PrestigeBadge.luau`
4. `PlayerCollision.luau`
5. `PlayerRole.luau`
6. `ServerSkipStageHandler.luau`
7. `AutomaticMembersToDonatorPromoter.luau`

From `src/admin/`:

8. `AdminTeleport.luau`

---

## 2. Tool Scripts

Each file in `src/tools/` is a `LocalScript` that must be parented **inside** its corresponding tool object.

| Script | Tool |
|---|---|
| `FlyingCarpet.luau` | Flying Carpet tool object |
| `GravityCoil.luau` | Gravity Coil tool object |
| `SpeedCoil.luau` | Speed Coil tool object |

Place the finished tool objects in **ServerStorage** and grant them to players via a gamepass handler or the **StarterPack**.

---

## 3. Workspace Setup

Create a `Folder` named exactly `Checkpoints` directly inside `Workspace`. Inside that folder, add `BasePart` objects named `Checkpoint1`, `Checkpoint2`, up to however many stages your obby has. The naming must match the pattern `Checkpoint<number>` exactly for the system to detect them.

If you want a prestige zone, add a `Part` named `PrestigeTrigger` anywhere in `Workspace`. The script will create a placeholder at `(0, 5, 0)` if none is found, but you should replace it with one positioned at the end of your course.

---

## 4. Configuration

Open each script and update the placeholder values:

**`PlayerRole.luau`**
```lua
local GROUP_ID = 0  -- your Roblox group ID
```

**`AutomaticMembersToDonatorPromoter.luau`**
```lua
local CONFIG = {
    GroupId        = 0,   -- your Roblox group ID
    DonatorRankId  = 0,   -- rank number to promote to
    RequiredRankMin = 1,
}
```

**`PrestigeBadge.luau`**
```lua
local PRESTIGE_BADGES = {
    [1]  = 123456789,  -- replace with actual badge IDs
    [5]  = 123456790,
    [10] = 123456791,
}
```

**`ServerSkipStageHandler.luau`**
```lua
local SKIP_GAMEPASSES = {
    Stage50  = 123456789,  -- replace with actual gamepass IDs
    Stage100 = 123456790,
    ...
}
```

**`AdminTeleport.luau`**
```lua
local ADMIN_IDS = {
    123456789,  -- your Roblox UserId
}
```

**`PrestigeScript.luau`**
```lua
local CONFIG = {
    Cooldown          = 1,   -- seconds
    RequiredObstacles = 100, -- stages required before prestiging
}
```

---

## 5. Publishing

1. Go to **File → Publish to Roblox As** if not already published.
2. Enable **API Services** under **Game Settings → Security** — required for DataStore access.
3. Run a live server test (not Studio playtest) to confirm DataStore reads and writes are working. Check the Output window for `[CheckpointSystem] Loaded ...` messages.
