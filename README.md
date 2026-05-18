# Pixel Climb

Server-side Luau codebase for Pixel Climb — a 240-stage precision platformer built on Roblox. This repository contains every script that runs on the server, including player progression, prestige, collision handling, tool logic, and admin utilities.

**Watch the demo:** [YouTube](https://www.youtube.com/watch?v=Yc1nPrDXe_E)


## How It Works

### Progression

Each stage is a `BasePart` named `Checkpoint<N>` inside a `Checkpoints` folder in Workspace. When a player touches a checkpoint the server compares the stage number against their stored furthest stage and only records forward progress. On rejoin the player spawns at their last checkpoint.

Two separate DataStores are used:

| DataStore | Key | Value |
|---|---|---|
| `CheckpointData` | `player_<UserId>` | Checkpoint name string, e.g. `"Checkpoint47"` |
| `PrestigeData` | `player_<UserId>` | Integer prestige level |

Saves are asynchronous (`task.spawn`) to avoid blocking gameplay. Both stores are read on join and written on leave, with an additional mid-session save on every new checkpoint reached.

### Prestige

A player who completes the required number of stages (default: 100) and touches the `PrestigeTrigger` part is shown a confirmation GUI. On confirmation the server resets their checkpoint and stage count, increments their prestige level, saves both DataStores, and reloads their character.

### Admin Teleport

The individual per-stage teleport scripts have been replaced by a single `AdminTeleport` handler. Clients fire a `RemoteEvent` with a target stage number or destination name. The server verifies the player's admin status before teleporting them, so exploiters cannot trigger it client-side.

---

## Setup

### Prerequisites

- Roblox Studio (any recent version)
- A published Roblox place (DataStore access requires a live game)
- The game's group ID if you intend to use `PlayerRole.luau` or `AutomaticMembersToDonatorPromoter.luau`

### Steps

1. Clone or download this repository.
2. Open your place file in Roblox Studio.
3. Move each script in `src/server/` into **ServerScriptService**.
4. Move each script in `src/tools/` into its corresponding tool object in **ServerStorage** or the **StarterPack**.
5. Move `src/admin/AdminTeleport.luau` into **ServerScriptService**.
6. Create a `Folder` named `Checkpoints` in Workspace and populate it with `BasePart` objects named `Checkpoint1`, `Checkpoint2`, etc.
7. Open `PlayerRole.luau` and `AutomaticMembersToDonatorPromoter.luau` and replace the placeholder `GROUP_ID` values with your actual group ID.
8. Open `PrestigeBadge.luau` and replace the placeholder badge IDs with your actual badge IDs.
9. Open `AdminTeleport.luau` and add your Roblox `UserId` to `ADMIN_IDS`.
10. Publish and test in a live server — DataStore calls do not work in Studio offline mode.

See [docs/setup.md](docs/setup.md) for a more detailed walkthrough.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

See [LICENSE](LICENSE).

---

*Built and maintained by [Apex Realms Studios](https://github.com/Abdidev1).*
