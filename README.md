# CS-like FPS — Godot 4 Edition

> A tactical first-person shooter inspired by Counter-Strike 1.6, rebuilt from the ground up in **Godot 4**.

## Why Godot?

The original Babylon.js prototype hit browser limitations fast—audio latency, pointer lock quirks, and single-threaded performance caps. Godot 4 gives us native desktop performance, real 3D navigation for AI bots, and a proper asset pipeline, all open-source.

## Tech Stack

| Layer | Tech |
|-------|------|
| Engine | Godot 4.4 (Forward+) |
| Language | GDScript |
| Physics | Godot Physics |
| AI | NavigationRegion3D + custom state machine |
| Networking | Godot Multiplayer API (future) |

## Project Structure

```
scenes/
  main.tscn          — Entry world + game manager
  player.tscn        — FPS player controller
  world.tscn         — Test arena (GridMap-based)
scripts/
  player.gd          — Movement, camera, input
  weapon.gd          — Shooting, reloading, switching
  game_manager.gd    — Round logic, score, spawning
assets/
  textures/          — Placeholder / procedural textures
  models/            — Weapon & character models (future)
  sounds/            — SFX & music
```

## Controls

| Action | Key |
|--------|-----|
| Move | WASD |
| Jump | Space |
| Crouch | Ctrl |
| Walk (slow) | Shift |
| Shoot | LMB |
| Aim | RMB |
| Reload | R |
| Weapon 1/2/3 | 1 / 2 / 3 |

## Roadmap

- [x] Godot 4 project scaffold
- [ ] GridMap test arena (de_dust2 blockout style)
- [ ] FPS controller with crouch & walk modifiers
- [ ] Weapon system (AK-47, M4A1, AWP, Glock, USP)
- [ ] Bot AI (patrol → investigate → attack)
- [ ] Round-based economy (buy menu, armor, grenades)
- [ ] Multiplayer (Godot multiplayer API)

## Run

1. Download [Godot 4.4](https://godotengine.org/)
2. Open `project.godot` in the Godot editor
3. Press **F5** or click the play button

## License

MIT
