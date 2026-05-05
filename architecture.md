# Architecture

This document explains how the scripts relate to each other and the data flow during a typical session.

---

## Script Dependency Map

```
CheckpointAndLeaderboard  (module — required by others)
        │
        ├── PrestigeScript         (requires CheckpointAndLeaderboard)
        ├── ServerSkipStageHandler (requires CheckpointAndLeaderboard)
        └── AdminTeleport          (requires CheckpointAndLeaderboard)

PlayerCollision     (standalone)
PlayerRole          (standalone)
PrestigeBadge       (listens to PrestigeEvent RemoteEvent)
AutomaticMembersToDonatorPromoter (standalone)

Tools (client-side LocalScripts, no server dependency)
    FlyingCarpet
    GravityCoil
    SpeedCoil
```

---

## Remote Events (ReplicatedStorage)

| Event | Direction | Purpose |
|---|---|---|
| `CheckpointReached` | Server → Client | Notifies the client UI of a new checkpoint |
| `InitProgress` | Server → Client | Sends total checkpoint count for progress bar |
| `PrestigeEvent` | Server → Client | Signals a completed prestige (used by PrestigeBadge) |
| `RequestPrestigeConfirm` | Client → Server | Player confirms or cancels a prestige attempt |
| `RequestSkipStage` | Client → Server | Client requests a gamepass stage skip |
| `AdminTeleport` | Client → Server | Admin requests a teleport to a specific stage |

All inbound events (`Client → Server`) are validated server-side. A client can fire any of them but the server will silently drop requests that fail authorisation or validation checks.

---

## Data Flow: Player Joins

```
PlayerAdded
  └─ PlayerService.new()        creates leaderstats folder and IntValues
  └─ PlayerService:loadData()   reads CheckpointData and PrestigeData from DataStore
  └─ InitProgress:FireClient()  sends TOTAL_CHECKPOINTS to the client progress bar
  └─ CharacterAdded             → PlayerService:spawn() teleports to last checkpoint
```

## Data Flow: Checkpoint Touched

```
BasePart.Touched
  └─ Players:GetPlayerFromCharacter()
  └─ PlayerService:reachedCheckpoint()
        ├─ compares stage number against current best
        ├─ if higher: updates obstaclesStat, fires CheckpointReached to client
        └─ task.spawn → DataStore:SetAsync (async, non-blocking)
```

## Data Flow: Prestige

```
PrestigeTrigger.Touched
  └─ canPrestige() check (stage count + cooldown)
  └─ PrestigeConfirmGui.Enabled = true  (on client)

RequestPrestigeConfirm fires (confirm = true)
  └─ performPrestige()
        └─ PlayerService:prestige()
              ├─ resets obstacles and checkpoint fields
              ├─ increments prestigeLevel
              ├─ task.spawn → saves PrestigeData, removes CheckpointData
              ├─ InitProgress:FireClient (reset progress bar)
              └─ player:LoadCharacter()
```

## Data Flow: Player Leaves

```
PlayerRemoving
  └─ PlayerService:saveData()   synchronous final save to both DataStores
  └─ activePlayers[player] = nil
```

---

## DataStore Keys

Both stores use the same key format: `player_<UserId>`.

`CheckpointData` stores a checkpoint name string such as `"Checkpoint47"`. The stage number is extracted at read time with a pattern match (`%d+$`). Storing the full name rather than just the number makes it easier to rename checkpoints without a migration.

`PrestigeData` stores a plain integer.
